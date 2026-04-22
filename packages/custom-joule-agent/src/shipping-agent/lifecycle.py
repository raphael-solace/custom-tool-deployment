"""
Lifecycle management for the Shipping Agent.
Implements required lifecycle hooks for Solace Agent Mesh custom agents.
Reference: https://github.com/SolaceLabs/solace-agent-mesh/blob/main/docs/docs/documentation/developing/tutorials/custom-agent.md
"""

import logging
from datetime import datetime, timezone


async def on_agent_start(agent_context: dict, logger=None):
    """
    Called when the agent starts up.
    Initialize resources, connections, or perform startup checks.
    """
    logger = logger or logging.getLogger(__name__)

    try:
        config = agent_context.get('config', {}) if agent_context else {}
        startup_message = config.get('startup_message', 'Shipping Agent started')
        logger.info(f"{startup_message}")

    except Exception as e:
        logger.error(f"Error during agent startup: {e}")

async def on_agent_stop(agent_context: dict, logger=None):
    """
    Called when the agent is shutting down.
    Clean up resources, close connections, etc.
    """
    logger = logger or logging.getLogger(__name__)

    try:
        logger.info("Shipping Agent stopping. Cleaning up resources...")

    except Exception as e:
        logger.error(f"Error during agent shutdown: {e}")

async def on_agent_health(agent_context: dict, logger=None) -> dict:
    """
    Called to check the health of the agent.

    Returns:
        Health status dictionary
    """
    logger = logger or logging.getLogger(__name__)

    try:
        health = {
            "status": "healthy",
            "timestamp": str(datetime.now(timezone.utc))
        }
        logger.debug(f"Health check: {health}")
        return health
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return {"status": "unhealthy", "error": str(e), "timestamp": str(datetime.now(timezone.utc))}

async def on_agent_config_update(agent_context: dict, new_config: dict, logger=None):
    """
    Called when the agent configuration is updated.
    Reload config or reinitialize resources.
    """
    logger = logger or logging.getLogger(__name__)

    try:
        logger.info(f"Shipping Agent config updated: {new_config}")

    except Exception as e:
        logger.error(f"Error during config update: {e}")
