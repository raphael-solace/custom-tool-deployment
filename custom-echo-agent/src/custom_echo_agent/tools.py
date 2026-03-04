"""Custom tools for the standalone custom echo agent."""

from typing import Any, Dict, Optional

from google.adk.tools import ToolContext


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
