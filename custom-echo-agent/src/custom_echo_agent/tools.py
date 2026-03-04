"""Custom tools for the standalone custom echo agent."""

import asyncio
from datetime import date, datetime, time
from decimal import Decimal
import re
from typing import Any, Dict, List, Optional

from google.adk.tools import ToolContext
import psycopg2
from psycopg2.extras import RealDictCursor


DEFAULT_RAG_DOCUMENTS = [
    "Solace Agent Mesh standalone agents run with deploymentMode standalone and one dedicated Helm release.",
    "Custom Python tools are imported from the image package and configured with tool_type python in config.yaml.",
    "For standalone compatibility, provide DATABASE_URL through a Kubernetes secret referenced in persistence.existingSecrets.database.",
    "Deployment verification should include rollout status, db-init logs, sam logs, and an in-pod Python import check.",
]


def _tokenize(text: str) -> List[str]:
    return re.findall(r"[a-z0-9]+", text.lower())


def _serialize_value(value: Any) -> Any:
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (dict, list)):
        return value
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _ensure_read_only_sql(sql: str) -> str:
    normalized = sql.strip().rstrip(";")
    lowered = normalized.lower()
    if not normalized:
        raise ValueError("SQL query cannot be empty.")
    if not (lowered.startswith("select") or lowered.startswith("with")):
        raise ValueError("Only SELECT/CTE read queries are allowed.")

    forbidden = (
        " insert ",
        " update ",
        " delete ",
        " drop ",
        " alter ",
        " create ",
        " truncate ",
        " grant ",
        " revoke ",
        " vacuum ",
        " analyze ",
        " execute ",
    )
    padded = f" {lowered} "
    for token in forbidden:
        if token in padded:
            raise ValueError(f"Forbidden SQL keyword detected: {token.strip().upper()}")
    return normalized


def _run_pg_select(
    database_url: str,
    sql: str,
    max_rows: int,
) -> Dict[str, Any]:
    safe_sql = _ensure_read_only_sql(sql)
    wrapped_sql = f"SELECT * FROM ({safe_sql}) AS _sam_subquery LIMIT %s"

    with psycopg2.connect(database_url, connect_timeout=10) as connection:
        with connection.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute(wrapped_sql, (max_rows,))
            rows = cursor.fetchall()
            columns = [desc.name for desc in cursor.description] if cursor.description else []

    serialized_rows = [
        {key: _serialize_value(value) for key, value in row.items()}
        for row in rows
    ]

    return {
        "columns": columns,
        "rows": serialized_rows,
        "row_count": len(serialized_rows),
        "max_rows": max_rows,
    }


async def healthcheck_echo(
    name: str,
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Return a deterministic healthcheck payload for deployment verification.

    Args:
        name: Caller-provided name.
        tool_context: Agent Mesh runtime context.
        tool_config: Optional tool configuration.

    Returns:
        Deterministic response used to verify custom code loading in-cluster.
    """
    prefix = "HELLO"
    if tool_config and isinstance(tool_config, dict):
        prefix = str(tool_config.get("prefix", "HELLO"))

    return {
        "status": "ok",
        "tool": "healthcheck_echo",
        "message": f"{prefix}::{name}",
        "deterministic": True,
        "has_tool_context": tool_context is not None,
    }


async def simple_rag(
    query: str,
    top_k: int = 2,
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Return simple deterministic retrieval results from a small local corpus."""
    if top_k < 1:
        top_k = 1

    documents: List[str] = DEFAULT_RAG_DOCUMENTS
    if tool_config and isinstance(tool_config, dict):
        configured_docs = tool_config.get("documents")
        if isinstance(configured_docs, list):
            cleaned = [str(doc).strip() for doc in configured_docs if str(doc).strip()]
            if cleaned:
                documents = cleaned

    query_tokens = set(_tokenize(query))
    scored = []
    for idx, doc in enumerate(documents):
        doc_tokens = set(_tokenize(doc))
        matched_terms = sorted(query_tokens & doc_tokens)
        score = len(matched_terms)
        scored.append(
            {
                "index": idx,
                "score": score,
                "matched_terms": matched_terms,
                "chunk": doc,
            }
        )

    scored.sort(key=lambda item: (-item["score"], item["index"]))
    top_results = scored[: min(top_k, len(scored))]

    best_score = top_results[0]["score"] if top_results else 0
    if best_score == 0:
        answer = "No strong lexical match found in the configured corpus."
    else:
        answer = " | ".join(result["chunk"] for result in top_results)

    return {
        "status": "ok",
        "tool": "simple_rag",
        "query": query,
        "top_k": top_k,
        "results": top_results,
        "answer": answer,
        "deterministic": True,
        "has_tool_context": tool_context is not None,
    }


async def query_external_postgres(
    sql: str,
    max_rows: int = 50,
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Run a read-only SQL query against an external PostgreSQL database."""
    config = tool_config or {}
    database_url = str(config.get("database_url", "")).strip()
    if not database_url:
        return {
            "status": "error",
            "tool": "query_external_postgres",
            "error": "Missing required tool_config.database_url",
        }

    configured_max = config.get("default_max_rows", max_rows)
    try:
        limit = int(configured_max)
    except (TypeError, ValueError):
        limit = max_rows
    limit = max(1, min(limit, 200))

    try:
        result = await asyncio.to_thread(_run_pg_select, database_url, sql, limit)
        return {
            "status": "ok",
            "tool": "query_external_postgres",
            "query": sql,
            "result": result,
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }
    except Exception as exc:
        return {
            "status": "error",
            "tool": "query_external_postgres",
            "query": sql,
            "error": str(exc),
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }
