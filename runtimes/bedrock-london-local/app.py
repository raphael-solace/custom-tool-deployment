import asyncio
import ast
import base64
import json
import logging
import os
import re
import struct
import zlib
from datetime import datetime, timezone
from functools import lru_cache
from typing import Any, Dict, List, Optional

from fastapi import FastAPI, HTTPException
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response
from langchain_core.messages import AIMessage, BaseMessage, HumanMessage
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent
from pydantic import BaseModel, ConfigDict

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
log = logging.getLogger("bedrock-london-local")

MAX_HISTORY_MESSAGES = 40
conversations: Dict[str, List[BaseMessage]] = {}
conversations_lock = asyncio.Lock()

SYSTEM_PROMPT = """
You are Bedrock Legal Agent, specialized in legal and compliance support.
Use tools when they improve accuracy.
Always answer clearly, with concise legal context and practical next steps.
Do not fabricate facts and do not claim attorney-client relationship.
""".strip()


@tool
def get_current_time() -> str:
    """Return the current UTC timestamp in ISO-8601 format."""
    return datetime.now(timezone.utc).isoformat()


def _safe_eval_math(expression: str) -> float:
    allowed_ops = {
        ast.Add: lambda a, b: a + b,
        ast.Sub: lambda a, b: a - b,
        ast.Mult: lambda a, b: a * b,
        ast.Div: lambda a, b: a / b,
        ast.Pow: lambda a, b: a**b,
        ast.USub: lambda a: -a,
        ast.UAdd: lambda a: a,
    }

    def eval_node(node: ast.AST) -> float:
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return float(node.value)
        if isinstance(node, ast.BinOp) and type(node.op) in allowed_ops:
            left = eval_node(node.left)
            right = eval_node(node.right)
            return allowed_ops[type(node.op)](left, right)
        if isinstance(node, ast.UnaryOp) and type(node.op) in allowed_ops:
            return allowed_ops[type(node.op)](eval_node(node.operand))
        raise ValueError("Expression contains unsupported syntax")

    parsed = ast.parse(expression, mode="eval")
    return eval_node(parsed.body)


@tool
def calculator(expression: str) -> str:
    """Evaluate a basic arithmetic expression like 2+2, (12/3)+5, or 3*7."""
    try:
        result = _safe_eval_math(expression)
        if result.is_integer():
            return str(int(result))
        return str(result)
    except Exception as exc:
        return f"Unable to evaluate expression '{expression}': {exc}"


TOOLS = [get_current_time, calculator]


class SimplifiedInvokeRequest(BaseModel):
    model_config = ConfigDict(extra="allow")

    agentId: str
    agentAliasId: str
    sessionId: str
    inputText: str
    enableTrace: Optional[bool] = None
    sessionState: Optional[Dict[str, Any]] = None


class AwsInvokeBody(BaseModel):
    model_config = ConfigDict(extra="allow")

    inputText: Optional[str] = None
    enableTrace: Optional[bool] = None
    sessionState: Optional[Dict[str, Any]] = None
    endSession: Optional[bool] = None


@lru_cache(maxsize=1)
def _get_react_agent():
    model_name = os.getenv(
        "BEDROCK_LONDON_LOCAL_MODEL",
        os.getenv("LLM_SERVICE_GENERAL_MODEL_NAME", "openai/bedrock-claude-4-5-sonnet"),
    )
    api_base = os.getenv("LLM_SERVICE_ENDPOINT", "").strip()
    api_key = os.getenv("LLM_SERVICE_API_KEY", "demo-key")

    model = ChatOpenAI(
        model=model_name,
        api_key=api_key,
        base_url=api_base or None,
        temperature=0,
    )
    return create_react_agent(model=model, tools=TOOLS, prompt=SYSTEM_PROMPT)


def _extract_last_ai_text(messages: List[BaseMessage]) -> str:
    for msg in reversed(messages):
        if isinstance(msg, AIMessage):
            if isinstance(msg.content, str) and msg.content.strip():
                return msg.content.strip()
            if msg.content:
                return json.dumps(msg.content)
    return "I can help with legal and compliance questions. Please provide more details."


def _deterministic_fallback(input_text: str) -> str:
    pieces: List[str] = []
    lower = input_text.lower()

    if "time" in lower or "date" in lower:
        pieces.append(f"Current UTC time: {datetime.now(timezone.utc).isoformat()}")

    expr_match = re.search(r"(-?\d+(?:\s*[-+*/]\s*-?\d+)+)", input_text)
    if expr_match:
        expression = expr_match.group(1)
        pieces.append(f"Calculation {expression} = {calculator.invoke({'expression': expression})}")

    if not pieces:
        pieces.append(
            "I can support legal/compliance-oriented analysis. Share jurisdiction, contract clause, or policy objective for a focused response."
        )

    return "\n".join(pieces)


async def _run_agent_turn(session_id: str, input_text: str) -> str:
    async with conversations_lock:
        history = list(conversations.get(session_id, []))

    turn_messages: List[BaseMessage] = history + [HumanMessage(content=input_text)]

    try:
        agent = _get_react_agent()
        result = await agent.ainvoke({"messages": turn_messages})
        new_messages = result.get("messages", turn_messages)
        answer = _extract_last_ai_text(new_messages)
    except Exception as exc:
        log.exception("ReAct execution error, switching to deterministic fallback: %s", exc)
        answer = _deterministic_fallback(input_text)
        new_messages = turn_messages + [AIMessage(content=answer)]

    async with conversations_lock:
        conversations[session_id] = new_messages[-MAX_HISTORY_MESSAGES:]

    return answer


def _encode_headers(headers: List[tuple[str, str]]) -> bytes:
    out = b""
    for name, value in headers:
        name_bytes = name.encode("utf-8")
        value_bytes = value.encode("utf-8")
        out += struct.pack("!B", len(name_bytes)) + name_bytes
        out += struct.pack("!B", 7) + struct.pack("!H", len(value_bytes)) + value_bytes
    return out


def _encode_eventstream_message(headers: List[tuple[str, str]], payload: bytes) -> bytes:
    header_bytes = _encode_headers(headers)
    total_length = 4 + 4 + 4 + len(header_bytes) + len(payload) + 4
    headers_length = len(header_bytes)

    prelude = struct.pack("!II", total_length, headers_length)
    prelude_crc = zlib.crc32(prelude) & 0xFFFFFFFF
    prelude_block = prelude + struct.pack("!I", prelude_crc)

    message_without_crc = prelude_block + header_bytes + payload
    message_crc = zlib.crc32(message_without_crc) & 0xFFFFFFFF
    return message_without_crc + struct.pack("!I", message_crc)


def _bedrock_chunk_event(answer_text: str) -> bytes:
    payload_obj = {
        "bytes": base64.b64encode(answer_text.encode("utf-8")).decode("ascii")
    }
    payload = json.dumps(payload_obj).encode("utf-8")
    return _encode_eventstream_message(
        headers=[
            (":message-type", "event"),
            (":event-type", "chunk"),
            (":content-type", "application/json"),
        ],
        payload=payload,
    )


app = FastAPI(title="bedrock-london-local", version="1.0.0")


@app.exception_handler(RequestValidationError)
async def _validation_exception_handler(_, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={"error": "validation_error", "details": exc.errors()},
    )


@app.exception_handler(HTTPException)
async def _http_exception_handler(_, exc: HTTPException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": "http_error", "details": exc.detail},
    )


@app.exception_handler(Exception)
async def _unexpected_exception_handler(_, exc: Exception):
    log.exception("Unhandled server error: %s", exc)
    return JSONResponse(
        status_code=500,
        content={"error": "internal_server_error", "details": str(exc)},
    )


@app.get("/healthz")
async def healthz():
    return {"status": "ok", "service": "bedrock-london-local"}


@app.post("/invoke-agent")
async def invoke_agent_simplified(payload: SimplifiedInvokeRequest):
    input_text = (payload.inputText or "").strip()
    if not input_text:
        raise HTTPException(status_code=400, detail="inputText must be provided")

    log.info(
        "invoke-agent request received agentId=%s alias=%s sessionId=%s",
        payload.agentId,
        payload.agentAliasId,
        payload.sessionId,
    )

    answer = await _run_agent_turn(payload.sessionId, input_text)
    return {
        "completion": {
            "text": answer,
            "sessionId": payload.sessionId,
            "agentId": payload.agentId,
            "agentAliasId": payload.agentAliasId,
        },
        "trace": None,
    }


@app.post("/agents/{agentId}/agentAliases/{agentAliasId}/sessions/{sessionId}/text")
async def invoke_agent_aws_style(
    agentId: str,
    agentAliasId: str,
    sessionId: str,
    payload: AwsInvokeBody,
):
    input_text = (payload.inputText or "").strip()
    if not input_text:
        raise HTTPException(status_code=400, detail="inputText must be provided")

    log.info(
        "AWS-style invoke_agent request received agentId=%s alias=%s sessionId=%s",
        agentId,
        agentAliasId,
        sessionId,
    )

    answer = await _run_agent_turn(sessionId, input_text)
    eventstream_payload = _bedrock_chunk_event(answer)

    return Response(
        content=eventstream_payload,
        media_type="application/vnd.amazon.eventstream",
        headers={
            "x-amzn-bedrock-agent-content-type": "application/json",
            "x-amz-bedrock-agent-session-id": sessionId,
        },
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
