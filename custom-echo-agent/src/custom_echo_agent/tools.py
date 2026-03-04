"""Custom tools for the standalone custom echo agent."""

from typing import Any, Dict, List, Optional

import re

from google.adk.tools import ToolContext


DEFAULT_RAG_DOCUMENTS = [
    "Solace Agent Mesh standalone agents run with deploymentMode standalone and one dedicated Helm release.",
    "Custom Python tools are imported from the image package and configured with tool_type python in config.yaml.",
    "For standalone compatibility, provide DATABASE_URL through a Kubernetes secret referenced in persistence.existingSecrets.database.",
    "Deployment verification should include rollout status, db-init logs, sam logs, and an in-pod Python import check.",
]


def _tokenize(text: str) -> List[str]:
    return re.findall(r"[a-z0-9]+", text.lower())


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
