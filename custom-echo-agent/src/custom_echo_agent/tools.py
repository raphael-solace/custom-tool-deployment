"""Custom tools for the standalone custom echo agent."""

import asyncio
from datetime import date, datetime, time
from decimal import Decimal
from io import BytesIO
import inspect as pyinspect
import json
import os
import re
from typing import Any, Dict, List, Optional
from pathlib import Path
import urllib.parse
import uuid

import boto3

from google.adk.tools import ToolContext
import psycopg2
from psycopg2.extras import RealDictCursor
from pypdf import PdfReader

try:
    from solace_agent_mesh.agent.utils.artifact_helpers import (
        load_artifact_content_or_metadata,
    )
except Exception:  # pragma: no cover - available in SAM runtime image
    load_artifact_content_or_metadata = None

try:
    from solace_agent_mesh.agent.utils.context_helpers import (
        get_original_session_id as sam_get_original_session_id,
    )
except Exception:  # pragma: no cover - available in SAM runtime image
    sam_get_original_session_id = None


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


def _summarize_pdf_reader(
    reader: PdfReader,
    query: str,
    page_limit: int,
    char_limit: int,
    result_limit: int,
) -> Dict[str, Any]:
    total_pages = len(reader.pages)
    use_pages = min(total_pages, page_limit)
    pages: List[Dict[str, Any]] = []
    full_text_parts: List[str] = []

    for idx in range(use_pages):
        page_text = (reader.pages[idx].extract_text() or "").strip()
        trimmed = page_text[:char_limit]
        pages.append(
            {
                "page": idx + 1,
                "chars": len(page_text),
                "excerpt": trimmed,
            }
        )
        if page_text:
            full_text_parts.append(page_text)

    full_text = "\n".join(full_text_parts)
    query_value = query.strip()

    if query_value:
        query_tokens = set(_tokenize(query_value))
        scored = []
        for page in pages:
            page_tokens = set(_tokenize(page["excerpt"]))
            matched_terms = sorted(query_tokens & page_tokens)
            scored.append(
                {
                    "page": page["page"],
                    "score": len(matched_terms),
                    "matched_terms": matched_terms,
                    "excerpt": page["excerpt"],
                }
            )
        scored.sort(key=lambda item: (-item["score"], item["page"]))
        top_matches = scored[:result_limit]
    else:
        top_matches = []

    metadata = {}
    for key, value in (reader.metadata or {}).items():
        if value is None:
            continue
        metadata[str(key)] = _serialize_value(value)

    return {
        "query": query_value,
        "summary": {
            "total_pages": total_pages,
            "processed_pages": use_pages,
            "non_empty_pages": len([p for p in pages if p["chars"] > 0]),
            "text_chars": len(full_text),
        },
        "metadata": metadata,
        "page_excerpts": pages,
        "top_matches": top_matches,
    }


def _dedupe_keep_order(values: List[str]) -> List[str]:
    seen = set()
    result: List[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        result.append(value)
    return result


def _select_artifact_candidates(artifacts: List[str], requested: str) -> List[str]:
    if not artifacts:
        return []

    if not requested:
        return [name for name in reversed(artifacts) if name.lower().endswith(".pdf")]

    requested_raw = requested.strip()
    requested_lower = requested_raw.lower()
    requested_base = Path(requested_raw).name.lower()

    exact = [name for name in artifacts if name == requested_raw]
    exact_ci = [name for name in artifacts if name.lower() == requested_lower]
    base = [name for name in artifacts if Path(name).name.lower() == requested_base]
    contains = [
        name
        for name in artifacts
        if requested_base and requested_base in Path(name).name.lower()
    ]
    pdf_only = [name for name in artifacts if name.lower().endswith(".pdf")]

    return _dedupe_keep_order(exact + exact_ci + base + contains + pdf_only)


def _normalize_filename(value: str) -> str:
    decoded = urllib.parse.unquote_plus(str(value))
    base = Path(decoded).name
    base = re.sub(r"\s+", " ", base).strip().lower()
    return base


def _extract_logical_filename_from_key(key: str) -> str:
    decoded_key = urllib.parse.unquote_plus(str(key))
    parts = list(Path(decoded_key).parts)
    if not parts:
        return ""

    tail = parts[-1]
    if tail.isdigit() and len(parts) >= 2:
        return parts[-2]
    return tail


def _is_pdf_key_match(key: str, requested: str) -> bool:
    logical_name = _extract_logical_filename_from_key(key)
    logical_lower = logical_name.lower()
    if not logical_lower.endswith(".pdf"):
        return False

    requested_raw = (requested or "").strip()
    if not requested_raw:
        return True

    req_norm = _normalize_filename(requested_raw)
    req_no_ext = req_norm[:-4] if req_norm.endswith(".pdf") else req_norm
    req_no_ext = req_no_ext.strip()

    key_norm = _normalize_filename(logical_name)
    key_no_ext = key_norm[:-4] if key_norm.endswith(".pdf") else key_norm

    if key_norm == req_norm:
        return True
    if key_no_ext and req_no_ext and key_no_ext == req_no_ext:
        return True
    if req_no_ext and req_no_ext in key_no_ext:
        return True
    return False


async def _maybe_await(value: Any) -> Any:
    if pyinspect.isawaitable(value):
        return await value
    return value


def _string_if_non_empty(value: Any) -> str:
    if value is None:
        return ""
    text = str(value).strip()
    return text


def _coerce_bool(value: Any, default: bool = False) -> bool:
    if isinstance(value, bool):
        return value
    if value is None:
        return default
    text = str(value).strip().lower()
    if text in {"1", "true", "yes", "on"}:
        return True
    if text in {"0", "false", "no", "off"}:
        return False
    return default


def _get_original_session_id_from_invocation(inv_context: Any) -> str:
    if sam_get_original_session_id is not None:
        try:
            session_id = sam_get_original_session_id(inv_context)
            if session_id:
                return str(session_id)
        except Exception:
            pass

    session = getattr(inv_context, "session", None)
    raw_session_id = _string_if_non_empty(getattr(session, "id", ""))
    if ":" in raw_session_id:
        return raw_session_id.split(":", 1)[0]
    return raw_session_id


def _collect_candidate_app_names(inv_context: Any, source_app_name: str) -> List[str]:
    session = getattr(inv_context, "session", None)
    values = [
        source_app_name,
        getattr(inv_context, "app_name", ""),
        getattr(inv_context, "source_app_name", ""),
        getattr(inv_context, "parent_app_name", ""),
        getattr(inv_context, "root_app_name", ""),
        getattr(session, "app_name", ""),
        getattr(session, "source_app_name", ""),
        getattr(session, "parent_app_name", ""),
    ]
    return _dedupe_keep_order([text for text in (_string_if_non_empty(v) for v in values) if text])[:8]


def _collect_candidate_session_ids(inv_context: Any, source_session_id: str) -> List[str]:
    session = getattr(inv_context, "session", None)
    raw_session_id = _string_if_non_empty(getattr(session, "id", ""))
    original_session_id = _get_original_session_id_from_invocation(inv_context)

    values = [
        source_session_id,
        getattr(inv_context, "session_id", ""),
        getattr(inv_context, "source_session_id", ""),
        getattr(inv_context, "parent_session_id", ""),
        getattr(inv_context, "root_session_id", ""),
        getattr(session, "source_session_id", ""),
        getattr(session, "parent_session_id", ""),
        getattr(session, "root_session_id", ""),
        raw_session_id,
        original_session_id,
    ]

    result: List[str] = []
    for value in values:
        text = _string_if_non_empty(value)
        if not text:
            continue
        result.append(text)
        if ":" in text:
            result.append(text.split(":", 1)[0])
    return _dedupe_keep_order(result)[:8]


def _collect_candidate_user_ids(inv_context: Any, source_user_id: str) -> List[str]:
    session = getattr(inv_context, "session", None)
    values = [
        source_user_id,
        getattr(inv_context, "user_id", ""),
        getattr(inv_context, "source_user_id", ""),
        getattr(session, "user_id", ""),
        getattr(session, "source_user_id", ""),
    ]
    return _dedupe_keep_order([text for text in (_string_if_non_empty(v) for v in values) if text])[:6]


def _load_pdf_from_bucket_storage_sync(
    file_hint: str,
    query_value: str,
    page_limit: int,
    char_limit: int,
    result_limit: int,
    bucket_prefix: str,
    max_scan_keys: int,
    max_candidates: int,
) -> Dict[str, Any]:
    endpoint_url = _string_if_non_empty(os.getenv("S3_ENDPOINT_URL"))
    bucket_name = _string_if_non_empty(os.getenv("S3_BUCKET_NAME"))
    access_key = _string_if_non_empty(os.getenv("AWS_ACCESS_KEY_ID"))
    secret_key = _string_if_non_empty(os.getenv("AWS_SECRET_ACCESS_KEY"))
    region = _string_if_non_empty(os.getenv("AWS_REGION")) or "us-east-1"

    if not endpoint_url or not bucket_name or not access_key or not secret_key:
        return {
            "status": "error",
            "error": "S3 environment is incomplete for bucket fallback",
        }

    try:
        client = boto3.client(
            "s3",
            endpoint_url=endpoint_url,
            region_name=region,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_key,
        )
    except Exception as exc:
        return {
            "status": "error",
            "error": f"Failed to initialize S3 client: {exc}",
        }

    continuation_token: Optional[str] = None
    scanned_keys = 0
    candidate_keys: List[Dict[str, Any]] = []
    list_errors: List[str] = []

    while True:
        request_kwargs: Dict[str, Any] = {"Bucket": bucket_name, "MaxKeys": 1000}
        if continuation_token:
            request_kwargs["ContinuationToken"] = continuation_token
        if bucket_prefix:
            request_kwargs["Prefix"] = bucket_prefix

        try:
            response = client.list_objects_v2(**request_kwargs)
        except Exception as exc:
            return {
                "status": "error",
                "error": f"Failed to list objects from artifact bucket: {exc}",
                "scanned_keys": scanned_keys,
            }

        contents = response.get("Contents", []) or []
        for obj in contents:
            key = str(obj.get("Key", ""))
            scanned_keys += 1
            if _is_pdf_key_match(key, file_hint):
                candidate_keys.append(
                    {
                        "key": key,
                        "last_modified": obj.get("LastModified"),
                    }
                )
            if scanned_keys >= max_scan_keys:
                break

        if scanned_keys >= max_scan_keys:
            break

        if response.get("IsTruncated"):
            continuation_token = _string_if_non_empty(
                response.get("NextContinuationToken")
            )
            if not continuation_token:
                break
        else:
            break

    if not candidate_keys:
        return {
            "status": "error",
            "error": "No matching PDF keys found in artifact bucket",
            "scanned_keys": scanned_keys,
            "bucket_prefix": bucket_prefix,
        }

    def _sort_ts(item: Dict[str, Any]) -> float:
        last_modified = item.get("last_modified")
        if hasattr(last_modified, "timestamp"):
            try:
                return float(last_modified.timestamp())
            except Exception:
                return 0.0
        return 0.0

    candidate_keys.sort(key=_sort_ts, reverse=True)

    selected_keys = [entry.get("key", "") for entry in candidate_keys[:max_candidates]]

    for key in selected_keys:
        if not key:
            continue
        try:
            obj = client.get_object(Bucket=bucket_name, Key=key)
            body = obj.get("Body")
            if body is None:
                list_errors.append(f"{key}: empty body")
                continue
            raw_bytes = body.read()
            if not raw_bytes:
                list_errors.append(f"{key}: zero-byte object")
                continue

            reader = PdfReader(BytesIO(raw_bytes))
            payload = _summarize_pdf_reader(
                reader=reader,
                query=query_value,
                page_limit=page_limit,
                char_limit=char_limit,
                result_limit=result_limit,
            )
            return {
                "status": "ok",
                "tool": "inspect_pdf",
                "source": {
                    "type": "artifact_bucket",
                    "bucket": bucket_name,
                    "key": key,
                    "endpoint_url": endpoint_url,
                },
                **payload,
                "deterministic": True,
                "has_tool_context": False,
            }
        except Exception as exc:
            list_errors.append(f"{key}: {exc}")
            continue

    return {
        "status": "error",
        "error": "Matching PDF keys were found but none were readable",
        "scanned_keys": scanned_keys,
        "bucket_prefix": bucket_prefix,
        "candidate_keys": selected_keys[:20],
        "bucket_errors": list_errors[:20],
    }


async def _load_pdf_from_artifact_service(
    tool_context: ToolContext,
    file_hint: str,
    query_value: str,
    page_limit: int,
    char_limit: int,
    result_limit: int,
    source_app_name: str,
    source_session_id: str,
    source_user_id: str,
) -> Dict[str, Any]:
    if tool_context is None:
        return {"status": "error", "error": "ToolContext missing"}
    if load_artifact_content_or_metadata is None:
        return {
            "status": "error",
            "error": "Shared artifact helper unavailable in runtime",
        }

    inv_context = getattr(tool_context, "_invocation_context", None)
    if inv_context is None:
        return {"status": "error", "error": "Invocation context unavailable"}

    artifact_service = getattr(inv_context, "artifact_service", None)
    if artifact_service is None:
        return {"status": "error", "error": "Artifact service unavailable"}

    list_keys_method = getattr(artifact_service, "list_artifact_keys", None)
    if list_keys_method is None:
        return {"status": "error", "error": "Artifact service does not support list_artifact_keys"}

    candidate_user_ids = _collect_candidate_user_ids(inv_context, source_user_id)
    candidate_apps = _collect_candidate_app_names(inv_context, source_app_name)
    candidate_sessions = _collect_candidate_session_ids(inv_context, source_session_id)

    if not candidate_user_ids or not candidate_apps or not candidate_sessions:
        return {
            "status": "error",
            "error": "Could not derive candidate user/app/session contexts for artifact lookup",
        }

    scanned_contexts: List[Dict[str, str]] = []
    lookup_errors: List[str] = []

    for user_id in candidate_user_ids:
        for app_name in candidate_apps:
            for session_id in candidate_sessions:
                scanned_contexts.append(
                    {
                        "user_id": user_id,
                        "app_name": app_name,
                        "session_id": session_id,
                    }
                )
                try:
                    keys_obj = list_keys_method(
                        app_name=app_name,
                        user_id=user_id,
                        session_id=session_id,
                    )
                    artifact_names = await _maybe_await(keys_obj)
                    if artifact_names is None:
                        artifact_names = []
                    elif not isinstance(artifact_names, list):
                        artifact_names = list(artifact_names)
                    artifact_names = [str(name) for name in artifact_names]
                except Exception as exc:
                    lookup_errors.append(f"{user_id}/{app_name}/{session_id}: {exc}")
                    continue

                candidates = _select_artifact_candidates(artifact_names, file_hint)
                for artifact_name in candidates:
                    try:
                        load_result = await load_artifact_content_or_metadata(
                            artifact_service=artifact_service,
                            app_name=app_name,
                            user_id=user_id,
                            session_id=session_id,
                            filename=artifact_name,
                            version="latest",
                            return_raw_bytes=True,
                            log_identifier_prefix="[custom_echo_agent.inspect_pdf]",
                        )
                    except Exception as exc:
                        lookup_errors.append(f"{user_id}/{app_name}/{session_id}/{artifact_name}: {exc}")
                        continue

                    if not isinstance(load_result, dict):
                        continue
                    if load_result.get("status") != "success":
                        continue

                    pdf_bytes = load_result.get("raw_bytes")
                    mime_type = str(load_result.get("mime_type", ""))
                    if not pdf_bytes:
                        continue
                    if mime_type and "pdf" not in mime_type.lower() and not artifact_name.lower().endswith(".pdf"):
                        continue

                    try:
                        reader = PdfReader(BytesIO(bytes(pdf_bytes)))
                        payload = _summarize_pdf_reader(
                            reader=reader,
                            query=query_value,
                            page_limit=page_limit,
                            char_limit=char_limit,
                            result_limit=result_limit,
                        )
                        return {
                            "status": "ok",
                            "tool": "inspect_pdf",
                            "source": {
                                "type": "artifact_service",
                                "artifact_name": artifact_name,
                                "user_id": user_id,
                                "app_name": app_name,
                                "session_id": session_id,
                                "version": load_result.get("version"),
                            },
                            **payload,
                            "deterministic": True,
                            "has_tool_context": True,
                        }
                    except Exception as exc:
                        lookup_errors.append(f"{user_id}/{app_name}/{session_id}/{artifact_name}: {exc}")
                        continue

    return {
        "status": "error",
        "error": "No readable PDF found in shared artifact contexts",
        "candidate_user_ids": candidate_user_ids,
        "candidate_apps": candidate_apps,
        "candidate_sessions": candidate_sessions,
        "scanned_contexts": scanned_contexts[:20],
        "lookup_errors": lookup_errors[:20],
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


def _coerce_publish_payload_text(payload: Any) -> str:
    if payload is None:
        return "{}"
    if isinstance(payload, str):
        text = payload.strip()
        return text if text else "{}"
    if isinstance(payload, (bytes, bytearray)):
        return bytes(payload).decode("utf-8", errors="replace")
    return json.dumps(payload, default=_serialize_value, ensure_ascii=False)


def _build_broker_connection_settings(tool_config: Optional[Dict[str, Any]]) -> Dict[str, str]:
    config = tool_config or {}

    def _pick(config_key: str, env_key: str) -> str:
        configured = _string_if_non_empty(config.get(config_key))
        if configured:
            return configured
        return _string_if_non_empty(os.getenv(env_key))

    return {
        "broker_url": _pick("broker_url", "SOLACE_BROKER_URL"),
        "broker_username": _pick("broker_username", "SOLACE_BROKER_USERNAME"),
        "broker_password": _pick("broker_password", "SOLACE_BROKER_PASSWORD"),
        "broker_vpn": _pick("broker_vpn", "SOLACE_BROKER_VPN"),
        "trust_store_path": _pick("trust_store_path", "SOLACE_TLS_TRUST_STORE_PATH"),
        "disable_certificate_validation": _string_if_non_empty(
            config.get("disable_certificate_validation")
        ),
    }


def _publish_event_sync(
    topic_name: str,
    payload_text: str,
    content_type: str,
    broker_settings: Dict[str, str],
) -> Dict[str, Any]:
    # Import at runtime so local editing/tests do not fail when Solace SDK is absent.
    import certifi

    from solace.messaging.config.authentication_strategy import BasicUserNamePassword
    from solace.messaging.config.solace_properties import (
        service_properties,
        transport_layer_properties,
        transport_layer_security_properties,
    )
    from solace.messaging.config.transport_security_strategy import TLS
    from solace.messaging.messaging_service import MessagingService
    from solace.messaging.resources.topic import Topic

    service = None
    publisher = None
    event_id = str(uuid.uuid4())

    try:
        trust_store_path = _string_if_non_empty(broker_settings.get("trust_store_path"))
        if not trust_store_path:
            trust_store_path = _string_if_non_empty(os.getenv("SSL_CERT_FILE"))
        if not trust_store_path:
            trust_store_path = _string_if_non_empty(certifi.where())

        service_props = {
            transport_layer_properties.HOST: broker_settings["broker_url"],
            service_properties.VPN_NAME: broker_settings["broker_vpn"],
        }
        if trust_store_path:
            service_props[transport_layer_security_properties.TRUST_STORE_PATH] = trust_store_path

        builder = MessagingService.builder().from_properties(service_props)
        builder = builder.with_authentication_strategy(
            BasicUserNamePassword.of(
                broker_settings["broker_username"],
                broker_settings["broker_password"],
            )
        )
        tls = TLS.create()
        if _coerce_bool(
            broker_settings.get("disable_certificate_validation"),
            default=False,
        ):
            tls = tls.without_certificate_validation()
        else:
            tls = tls.with_certificate_validation(
                ignore_expiration=False,
                validate_server_name=True,
                trust_store_file_path=trust_store_path or None,
            )
        builder = builder.with_transport_security_strategy(tls)

        service = builder.build()
        service.connect()

        publisher = service.create_direct_message_publisher_builder().build()
        publisher.start()

        message_builder = service.message_builder()
        with_msg_id = getattr(message_builder, "with_application_message_id", None)
        if callable(with_msg_id):
            try:
                message_builder = with_msg_id(event_id)
            except Exception:
                pass

        with_content_type = getattr(message_builder, "with_http_content_type", None)
        if callable(with_content_type) and content_type:
            try:
                message_builder = with_content_type(content_type)
            except Exception:
                pass

        outbound_message = message_builder.build(payload=payload_text)
        topic_destination = Topic.of(topic_name)

        publish_errors: List[str] = []
        published = False
        publish_fn = getattr(publisher, "publish")

        # Support minor SDK publish signature variations.
        for attempt in (
            "publish(message, topic_destination=topic)",
            "publish(message, destination=topic)",
            "publish(message, topic)",
        ):
            try:
                if attempt == "publish(message, topic_destination=topic)":
                    publish_fn(outbound_message, topic_destination=topic_destination)
                elif attempt == "publish(message, destination=topic)":
                    publish_fn(outbound_message, destination=topic_destination)
                else:
                    publish_fn(outbound_message, topic_destination)
                published = True
                break
            except TypeError as exc:
                publish_errors.append(f"{attempt}: {exc}")
                continue

        if not published:
            raise RuntimeError(
                "Could not publish with available SDK signatures. "
                + " | ".join(publish_errors)
            )

        return {
            "event_id": event_id,
            "topic": topic_name,
            "payload_chars": len(payload_text),
            "trust_store_path": trust_store_path,
            "certificate_validation_disabled": _coerce_bool(
                broker_settings.get("disable_certificate_validation"),
                default=False,
            ),
        }
    finally:
        if publisher is not None:
            terminate = getattr(publisher, "terminate", None)
            if callable(terminate):
                try:
                    terminate()
                except Exception:
                    pass
            else:
                stop = getattr(publisher, "stop", None)
                if callable(stop):
                    try:
                        stop()
                    except Exception:
                        pass

        if service is not None:
            disconnect = getattr(service, "disconnect", None)
            if callable(disconnect):
                try:
                    disconnect()
                except Exception:
                    pass


async def publish_event(
    topic: str,
    payload: Any,
    content_type: str = "application/json",
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Publish an event payload to a Solace topic using direct publish."""
    topic_name = _string_if_non_empty(topic)
    if not topic_name:
        return {
            "status": "error",
            "tool": "publish_event",
            "error": "Missing required topic",
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }

    config = tool_config or {}
    topic_prefix = _string_if_non_empty(config.get("topic_prefix"))
    if topic_prefix:
        topic_name = f"{topic_prefix.rstrip('/')}/{topic_name.lstrip('/')}"

    payload_text = _coerce_publish_payload_text(payload)
    try:
        max_payload_chars = int(config.get("max_payload_chars", 100000))
    except (TypeError, ValueError):
        max_payload_chars = 100000
    max_payload_chars = max(1000, min(max_payload_chars, 2_000_000))

    if len(payload_text) > max_payload_chars:
        return {
            "status": "error",
            "tool": "publish_event",
            "error": f"Payload is too large: {len(payload_text)} chars (max {max_payload_chars})",
            "topic": topic_name,
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }

    broker_settings = _build_broker_connection_settings(config)
    missing_fields = [
        key
        for key, value in broker_settings.items()
        if key in {"broker_url", "broker_username", "broker_password", "broker_vpn"}
        and not _string_if_non_empty(value)
    ]
    if missing_fields:
        return {
            "status": "error",
            "tool": "publish_event",
            "error": "Missing broker settings",
            "missing_fields": missing_fields,
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }

    try:
        publish_result = await asyncio.to_thread(
            _publish_event_sync,
            topic_name,
            payload_text,
            _string_if_non_empty(content_type) or "application/json",
            broker_settings,
        )
        return {
            "status": "ok",
            "tool": "publish_event",
            "message": "Event published",
            "topic": publish_result.get("topic", topic_name),
            "event_id": publish_result.get("event_id"),
            "payload_chars": publish_result.get("payload_chars", len(payload_text)),
            "trust_store_path": publish_result.get("trust_store_path"),
            "certificate_validation_disabled": publish_result.get(
                "certificate_validation_disabled",
                False,
            ),
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }
    except Exception as exc:
        return {
            "status": "error",
            "tool": "publish_event",
            "error": str(exc),
            "topic": topic_name,
            "deterministic": True,
            "has_tool_context": tool_context is not None,
        }


async def inspect_pdf(
    file_path: Optional[str] = None,
    query: Optional[str] = None,
    max_pages: int = 20,
    max_chars_per_page: int = 2000,
    top_k: int = 3,
    source_app_name: Optional[str] = None,
    source_session_id: Optional[str] = None,
    source_user_id: Optional[str] = None,
    search_shared_artifacts: bool = True,
    search_bucket_artifacts: bool = True,
    bucket_prefix: Optional[str] = "",
    bucket_max_scan_keys: int = 3000,
    bucket_max_candidates: int = 20,
    tool_context: Optional[ToolContext] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Inspect PDF content from filesystem path or chat artifacts.

    Lookup order:
    1) Local filesystem (allowed roots)
    2) ToolContext artifact view (current agent-visible artifacts)
    3) Shared ArtifactService contexts (same user + candidate app/session IDs)
    """

    try:
        page_limit = max(1, min(int(max_pages), 200))
    except (TypeError, ValueError):
        page_limit = 20
    try:
        char_limit = max(200, min(int(max_chars_per_page), 10000))
    except (TypeError, ValueError):
        char_limit = 2000
    try:
        result_limit = max(1, min(int(top_k), 10))
    except (TypeError, ValueError):
        result_limit = 3

    config = tool_config or {}
    allowed_roots = config.get("allowed_roots")
    if not isinstance(allowed_roots, list) or not allowed_roots:
        allowed_roots = ["/tmp", "/app"]

    if not source_app_name:
        source_app_name = _string_if_non_empty(config.get("source_app_name"))
    if not source_session_id:
        source_session_id = _string_if_non_empty(config.get("source_session_id"))
    if not source_user_id:
        source_user_id = _string_if_non_empty(config.get("source_user_id"))
    if not bucket_prefix:
        bucket_prefix = _string_if_non_empty(config.get("bucket_prefix"))

    if "search_bucket_artifacts" in config:
        search_bucket_artifacts = _coerce_bool(
            config.get("search_bucket_artifacts"),
            default=search_bucket_artifacts,
        )
    if "bucket_max_scan_keys" in config:
        try:
            bucket_max_scan_keys = int(config.get("bucket_max_scan_keys"))
        except (TypeError, ValueError):
            pass
    if "bucket_max_candidates" in config:
        try:
            bucket_max_candidates = int(config.get("bucket_max_candidates"))
        except (TypeError, ValueError):
            pass

    if "search_shared_artifacts" in config:
        search_shared_artifacts = _coerce_bool(
            config.get("search_shared_artifacts"),
            default=search_shared_artifacts,
        )

    file_hint = (file_path or "").strip()
    query_value = (query or "").strip()

    fs_attempted_path = ""
    fs_error = ""
    try:
        if file_hint:
            target = Path(file_hint).expanduser()
            if not target.is_absolute():
                target = Path("/tmp") / target
            resolved = target.resolve(strict=False)
            fs_attempted_path = str(resolved)

            allowed = False
            for root in allowed_roots:
                root_path = Path(str(root)).expanduser().resolve(strict=False)
                try:
                    resolved.relative_to(root_path)
                    allowed = True
                    break
                except ValueError:
                    continue

            if not allowed:
                fs_error = "Path is outside allowed roots"
            elif not resolved.exists():
                fs_error = "PDF file not found on filesystem"
            else:
                reader = PdfReader(str(resolved))
                payload = _summarize_pdf_reader(
                    reader=reader,
                    query=query_value,
                    page_limit=page_limit,
                    char_limit=char_limit,
                    result_limit=result_limit,
                )
                return {
                    "status": "ok",
                    "tool": "inspect_pdf",
                    "source": {
                        "type": "filesystem",
                        "path": str(resolved),
                    },
                    **payload,
                    "deterministic": True,
                    "has_tool_context": tool_context is not None,
                }
    except Exception as exc:
        fs_error = str(exc)

    artifact_error = ""
    available_pdf_artifacts: List[str] = []
    if tool_context is not None:
        try:
            artifact_names_obj = tool_context.list_artifacts()
            artifact_names = await _maybe_await(artifact_names_obj)
            if artifact_names is None:
                artifact_names = []
            elif not isinstance(artifact_names, list):
                artifact_names = list(artifact_names)
            artifact_names = [str(name) for name in artifact_names]
            available_pdf_artifacts = [
                name for name in artifact_names if name.lower().endswith(".pdf")
            ]
            candidates = _select_artifact_candidates(artifact_names, file_hint)

            for artifact_name in candidates:
                try:
                    part_obj = tool_context.load_artifact(artifact_name)
                    part = await _maybe_await(part_obj)
                    if part is None:
                        continue

                    inline_data = getattr(part, "inline_data", None)
                    blob_data = getattr(inline_data, "data", None) if inline_data else None
                    blob_mime = getattr(inline_data, "mime_type", "") if inline_data else ""

                    if not blob_data:
                        continue
                    if blob_mime and "pdf" not in blob_mime.lower() and not artifact_name.lower().endswith(".pdf"):
                        continue

                    if isinstance(blob_data, str):
                        pdf_bytes = blob_data.encode("utf-8", errors="ignore")
                    else:
                        pdf_bytes = bytes(blob_data)

                    reader = PdfReader(BytesIO(pdf_bytes))
                    payload = _summarize_pdf_reader(
                        reader=reader,
                        query=query_value,
                        page_limit=page_limit,
                        char_limit=char_limit,
                        result_limit=result_limit,
                    )
                    return {
                        "status": "ok",
                        "tool": "inspect_pdf",
                        "source": {
                            "type": "artifact",
                            "artifact_name": artifact_name,
                        },
                        **payload,
                        "deterministic": True,
                        "has_tool_context": True,
                    }
                except Exception as exc:
                    artifact_error = str(exc)
                    continue
        except Exception as exc:
            artifact_error = str(exc)

    shared_lookup_error = ""
    shared_lookup_contexts: List[Dict[str, str]] = []
    if tool_context is not None and search_shared_artifacts:
        shared_result = await _load_pdf_from_artifact_service(
            tool_context=tool_context,
            file_hint=file_hint,
            query_value=query_value,
            page_limit=page_limit,
            char_limit=char_limit,
            result_limit=result_limit,
            source_app_name=_string_if_non_empty(source_app_name),
            source_session_id=_string_if_non_empty(source_session_id),
            source_user_id=_string_if_non_empty(source_user_id),
        )
        if shared_result.get("status") == "ok":
            return shared_result
        shared_lookup_error = str(shared_result.get("error", "")).strip()
        shared_lookup_contexts = shared_result.get("scanned_contexts", [])[:20]
        candidate_user_ids = shared_result.get("candidate_user_ids")
        candidate_apps = shared_result.get("candidate_apps")
        candidate_sessions = shared_result.get("candidate_sessions")
    else:
        candidate_user_ids = []
        candidate_apps = []
        candidate_sessions = []

    bucket_lookup_error = ""
    bucket_lookup_scanned = 0
    bucket_lookup_candidates: List[str] = []
    if search_bucket_artifacts:
        try:
            bucket_max_scan_keys = int(bucket_max_scan_keys)
        except (TypeError, ValueError):
            bucket_max_scan_keys = 3000
        try:
            bucket_max_candidates = int(bucket_max_candidates)
        except (TypeError, ValueError):
            bucket_max_candidates = 20

        bucket_max_scan_keys = max(100, min(bucket_max_scan_keys, 20000))
        bucket_max_candidates = max(1, min(bucket_max_candidates, 100))

        bucket_result = await asyncio.to_thread(
            _load_pdf_from_bucket_storage_sync,
            file_hint,
            query_value,
            page_limit,
            char_limit,
            result_limit,
            _string_if_non_empty(bucket_prefix),
            bucket_max_scan_keys,
            bucket_max_candidates,
        )
        if bucket_result.get("status") == "ok":
            bucket_result["has_tool_context"] = tool_context is not None
            return bucket_result

        bucket_lookup_error = str(bucket_result.get("error", "")).strip()
        try:
            bucket_lookup_scanned = int(bucket_result.get("scanned_keys", 0))
        except (TypeError, ValueError):
            bucket_lookup_scanned = 0
        bucket_lookup_candidates = [
            str(key)
            for key in bucket_result.get("candidate_keys", [])[:20]
            if str(key).strip()
        ]

    details: Dict[str, Any] = {
        "query": query_value,
        "deterministic": True,
        "has_tool_context": tool_context is not None,
    }
    if fs_attempted_path:
        details["path"] = fs_attempted_path
    if fs_error:
        details["filesystem_error"] = fs_error
        details["allowed_roots"] = [str(Path(str(root)).expanduser()) for root in allowed_roots]
    if artifact_error:
        details["artifact_error"] = artifact_error
    if shared_lookup_error:
        details["shared_artifact_error"] = shared_lookup_error
    if candidate_user_ids:
        details["candidate_user_ids"] = candidate_user_ids[:20]
    if candidate_apps:
        details["candidate_apps"] = candidate_apps[:20]
    if candidate_sessions:
        details["candidate_sessions"] = candidate_sessions[:20]
    if shared_lookup_contexts:
        details["scanned_shared_contexts"] = shared_lookup_contexts
    if bucket_lookup_error:
        details["bucket_artifact_error"] = bucket_lookup_error
    if bucket_lookup_scanned:
        details["bucket_scanned_keys"] = bucket_lookup_scanned
    if bucket_lookup_candidates:
        details["bucket_candidate_keys"] = bucket_lookup_candidates
    if available_pdf_artifacts:
        details["available_pdf_artifacts"] = available_pdf_artifacts[:20]

    return {
        "status": "error",
        "tool": "inspect_pdf",
        "error": "No readable PDF found. Attach a PDF in chat and pass its filename, or omit file_path to use the latest attached PDF artifact.",
        **details,
    }
