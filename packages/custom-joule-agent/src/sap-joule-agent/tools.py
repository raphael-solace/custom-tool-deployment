"""
Tool module for integrating with SAP Joule Agent and delegating tasks to the agent.

This module defines tool functions for invoking the various SAP Joule APIs required for:
- Creating a new thread/conversation for a given Joule agent id
- Sending messages to the created thread/conversation
- Retrieving messages from the thread/conversation

Each function is documented for LLM usage and agent orchestration.
"""
import json
import os
import re
import uuid
import logging
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional, Tuple
import aiohttp
from aiohttp import ClientSession, TCPConnector, ClientError

# Configure module logger
logger = logging.getLogger(__name__)


MOCK_SKU_CATALOG: Dict[str, Dict[str, Any]] = {
    "MAT-200120": {
        "product_name": "Pressure Sensor Industrial 0-16 bar",
        "unit_price": 210.00,
        "available_to_promise": 180,
        "lead_time_days": 5,
        "uom": "EA",
        "aliases": ["pressure sensor", "pressure sensors"],
        "substitute_sku": "MAT-500200",
        "substitute_reason": "Inline flow meter option for broader instrumentation coverage when direct pressure-sensor stock is constrained.",
    },
    "MAT-300080": {
        "product_name": "Valve Controller Electro-Pneumatic",
        "unit_price": 340.00,
        "available_to_promise": 196,
        "lead_time_days": 4,
        "uom": "EA",
        "aliases": ["valve controller", "valve controllers", "electro-pneumatic valve controller"],
        "substitute_sku": "MAT-700200",
        "substitute_reason": "Gasket set is not a functional substitute. Keep split shipment as the only viable fallback unless customer changes requirements.",
    },
    "MAT-400060": {
        "product_name": "Hydraulic Pump Kit HPK-60",
        "unit_price": 1250.00,
        "available_to_promise": 72,
        "lead_time_days": 3,
        "uom": "EA",
        "aliases": ["hydraulic pump kit", "hydraulic pump kits"],
        "substitute_sku": None,
        "substitute_reason": None,
    },
    "MAT-500200": {
        "product_name": "Flow Meter FM-200 Inline",
        "unit_price": 460.00,
        "available_to_promise": 260,
        "lead_time_days": 6,
        "uom": "EA",
        "aliases": ["flow meter", "flow meters"],
        "substitute_sku": "MAT-200120",
        "substitute_reason": "Pressure sensor alternative for a narrower instrumentation scope only when customer accepts functional downgrade.",
    },
    "MAT-700200": {
        "product_name": "Gasket Set GS-200 Chemical Resistant",
        "unit_price": 18.00,
        "available_to_promise": 420,
        "lead_time_days": 2,
        "uom": "EA",
        "aliases": ["gasket set", "gasket sets"],
        "substitute_sku": None,
        "substitute_reason": None,
    },
}

MOCK_WAREHOUSES: Dict[str, Dict[str, str]] = {
    "FR:PARIS": {
        "code": "FR01",
        "name": "Paris Central Distribution Hub",
        "address": "14 Rue des Logistics, 92230 Gennevilliers, France",
    },
    "FR:LYON": {
        "code": "FR02",
        "name": "Lyon Recovery Fulfilment Hub",
        "address": "28 Boulevard de l'Industrie, 69800 Saint-Priest, France",
    },
    "NL:ROTTERDAM": {
        "code": "NL01",
        "name": "Rotterdam Inland Distribution Hub",
        "address": "88 Maasvlakte Logistics Park, 3199 LJ Rotterdam, Netherlands",
    },
    "IT:MILAN": {
        "code": "IT01",
        "name": "Milan Industrial Service Hub",
        "address": "51 Via del Commercio, 20090 Segrate, Italy",
    },
    "DEFAULT": {
        "code": "DE01",
        "name": "Cologne Export Coordination Center",
        "address": "12 Am Rheinhafen, 50997 Cologne, Germany",
    },
}

COUNTRY_BY_CITY: Dict[str, str] = {
    "PARIS": "FR",
    "LYON": "FR",
    "ROTTERDAM": "NL",
    "MILAN": "IT",
}

COUNTRY_NAME_TO_CODE: Dict[str, str] = {
    "FRANCE": "FR",
    "FRENCH REPUBLIC": "FR",
    "NETHERLANDS": "NL",
    "THE NETHERLANDS": "NL",
    "ITALY": "IT",
    "GERMANY": "DE",
}


def _env_flag(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() in {"1", "true", "yes", "on"}


def _extract_line_items(request_text: str) -> List[Dict[str, Any]]:
    line_items: List[Dict[str, Any]] = []
    seen: set[Tuple[str, int]] = set()

    patterns = [
        re.compile(r'(?P<quantity>\d+)\s+[^\n()]*?\(SKU\s+(?P<sku>MAT-\d{6})\)', re.IGNORECASE),
        re.compile(r'Material:\s*(?P<sku>MAT-\d{6}).*?Quantity:\s*(?P<quantity>\d+)', re.IGNORECASE | re.DOTALL),
        re.compile(r'(?P<sku>MAT-\d{6})\s+quantity\s+(?P<quantity>\d+)', re.IGNORECASE),
        re.compile(r'(?P<sku>MAT-\d{6}).{0,40}?(?P<quantity>\d+)\s*(?:EA|PCS|PC|units?)', re.IGNORECASE),
    ]

    for pattern in patterns:
        for match in pattern.finditer(request_text):
            sku = match.group("sku").upper()
            quantity = int(match.group("quantity"))
            key = (sku, quantity)
            if key in seen or sku not in MOCK_SKU_CATALOG:
                continue
            seen.add(key)
            line_items.append({"sku": sku, "quantity": quantity})

    if line_items:
        return line_items

    upper_text = request_text.upper()
    for sku, catalog_entry in MOCK_SKU_CATALOG.items():
        for alias in catalog_entry.get("aliases", []):
            alias_pattern = re.compile(rf'(?P<quantity>\d+)\s+{re.escape(alias)}', re.IGNORECASE)
            alias_match = alias_pattern.search(request_text)
            quantity = None
            if alias_match:
                quantity = int(alias_match.group("quantity"))
            elif alias.upper() in upper_text:
                generic_qty = re.search(r'\b(\d+)\b', request_text)
                quantity = int(generic_qty.group(1)) if generic_qty else 1

            if quantity is not None:
                key = (sku, quantity)
                if key not in seen:
                    seen.add(key)
                    line_items.append({"sku": sku, "quantity": quantity})
                break

    return line_items


def _extract_customer(request_text: str) -> Optional[str]:
    customer_match = re.search(r'Customer:\s*(.+)', request_text, re.IGNORECASE)
    if customer_match:
        return customer_match.group(1).strip()
    sender_match = re.search(r'From:\s*([^\s]+)', request_text, re.IGNORECASE)
    if sender_match:
        return sender_match.group(1).strip()
    return None


def _extract_destination(request_text: str) -> Tuple[str, str]:
    city = ""
    country = ""

    for label in ("Destination", "Delivery destination", "delivery in"):
        if label == "delivery in":
            match = re.search(r'delivery in\s+([A-Za-z -]+),\s*([A-Za-z -]+)', request_text, re.IGNORECASE)
        else:
            match = re.search(rf'{label}:\s*([A-Za-z -]+),\s*([A-Za-z -]+)', request_text, re.IGNORECASE)
        if match:
            city = match.group(1).strip().upper()
            country = match.group(2).strip().upper().rstrip(".")
            break

    if not city:
        for known_city in COUNTRY_BY_CITY:
            if known_city in request_text.upper():
                city = known_city
                country = COUNTRY_BY_CITY[known_city]
                break

    if not country and city:
        country = COUNTRY_BY_CITY.get(city, "DE")

    country = COUNTRY_NAME_TO_CODE.get(country, country)

    return city or "COLOGNE", country or "DE"


def _extract_requested_date(request_text: str) -> Optional[date]:
    match = re.search(r'(?:Requested delivery date|Need-by date|Original requested delivery date):\s*(\d{4}-\d{2}-\d{2})', request_text, re.IGNORECASE)
    if not match:
        return None
    try:
        return date.fromisoformat(match.group(1))
    except ValueError:
        return None


def _extract_incoterm(request_text: str) -> str:
    match = re.search(r'Incoterm:\s*([A-Z]{3})', request_text, re.IGNORECASE)
    return (match.group(1).upper() if match else "DAP")


def _select_warehouse(city: str, country: str) -> Dict[str, str]:
    return MOCK_WAREHOUSES.get(f"{country}:{city}", MOCK_WAREHOUSES["DEFAULT"])


def _detect_scenario_type(request_text: str) -> str:
    upper_text = request_text.upper()
    if "DELAYED ORDER" in upper_text or "SO-" in upper_text or "REMEDIATION" in upper_text:
        return "order_exception"
    if "REPLENISHMENT" in upper_text:
        return "replenishment"
    return "rfq"


def _default_line_items_for_request(request_text: str, scenario_type: str, city: str) -> List[Dict[str, Any]]:
    upper_text = request_text.upper()
    if scenario_type == "order_exception":
        return [{"sku": "MAT-300080", "quantity": 80}]
    if scenario_type == "replenishment":
        return [
            {"sku": "MAT-200120", "quantity": 120},
            {"sku": "MAT-300080", "quantity": 80},
        ]
    if "ROTTERDAM" in upper_text or "PUMP" in upper_text:
        return [{"sku": "MAT-400060", "quantity": 60}]
    if "MILAN" in upper_text or "FLOW" in upper_text or "GASKET" in upper_text:
        return [
            {"sku": "MAT-500200", "quantity": 200},
            {"sku": "MAT-700200", "quantity": 200},
        ]
    if "PRESSURE" in upper_text and "VALVE" in upper_text:
        return [
            {"sku": "MAT-200120", "quantity": 120},
            {"sku": "MAT-300080", "quantity": 80},
        ]
    if city == "LYON":
        return [{"sku": "MAT-300080", "quantity": 80}]
    return [{"sku": "MAT-300080", "quantity": 80}]


def _estimate_delivery_date(requested_date: Optional[date], lead_time_days: int) -> str:
    base_date = requested_date or (date.today() + timedelta(days=lead_time_days))
    return (base_date if requested_date else date.today() + timedelta(days=lead_time_days)).isoformat()


def _build_mock_joule_payload(request_text: str) -> Dict[str, Any]:
    scenario_type = _detect_scenario_type(request_text)
    city, country = _extract_destination(request_text)
    line_items = _extract_line_items(request_text)
    defaulted_line_items = False
    if not line_items:
        line_items = _default_line_items_for_request(request_text, scenario_type, city)
        defaulted_line_items = True
    warehouse = _select_warehouse(city, country)
    requested_date = _extract_requested_date(request_text)
    incoterm = _extract_incoterm(request_text)
    customer_name = _extract_customer(request_text)
    order_reference_match = re.search(r'\b(SO-\d{4}-\d{4})\b', request_text, re.IGNORECASE)
    order_reference = order_reference_match.group(1).upper() if order_reference_match else None

    materialized_items: List[Dict[str, Any]] = []
    total_cost = 0.0
    max_lead_time = 0
    blockers: List[str] = []
    global_notes = [
        f"Warehouse allocation anchored to {warehouse['code']} for {city.title()}, {country}.",
        "Fallback mode active: deterministic SAP-equivalent scenario data is being used while live Joule is unavailable.",
    ]
    assumptions = []
    if defaulted_line_items:
        assumptions.append("No explicit or parseable SKU/quantity pair was found in the incoming request text; applied the closest matching golden-scenario defaults to keep execution moving.")

    if requested_date is None:
        assumptions.append("Requested delivery date not provided explicitly; lead-time estimate anchored from current processing date.")

    if scenario_type == "order_exception":
        blockers.append("Original shipment missed planned departure window on the previously assigned lane.")
        global_notes.append("Recovery recommendation prioritizes fastest feasible re-source lane with available ATP.")

    for item in line_items:
        sku = item["sku"]
        quantity = item["quantity"]
        catalog_entry = MOCK_SKU_CATALOG[sku]
        confirmed_quantity = min(quantity, catalog_entry["available_to_promise"])
        remaining_after_commit = catalog_entry["available_to_promise"] - confirmed_quantity
        unit_price = catalog_entry["unit_price"]
        extended_price = round(unit_price * confirmed_quantity, 2)
        lead_time_days = catalog_entry["lead_time_days"] + (1 if scenario_type == "replenishment" else 0)
        max_lead_time = max(max_lead_time, lead_time_days)

        line_blockers: List[str] = []
        if confirmed_quantity < quantity:
            shortage = quantity - confirmed_quantity
            line_blockers.append(f"ATP shortfall of {shortage} units on {sku}; split shipment or substitute analysis required.")
            blockers.append(line_blockers[-1])

        total_cost += extended_price
        materialized_items.append({
            "sku": sku,
            "product_name": catalog_entry["product_name"],
            "requested_quantity": quantity,
            "confirmed_quantity": confirmed_quantity,
            "uom": catalog_entry["uom"],
            "inventory": {
                "availableToPromise": catalog_entry["available_to_promise"],
                "confirmedQuantity": confirmed_quantity,
                "remainingAfterCommit": remaining_after_commit,
                "stockStatus": "in_stock" if confirmed_quantity >= quantity else "partial",
                "availableFrom": date.today().isoformat(),
            },
            "pricing": {
                "unitPrice": unit_price,
                "extendedPrice": extended_price,
                "currency": "EUR",
            },
            "sourcing": {
                "selectedWarehouseCode": warehouse["code"],
                "selectedWarehouseName": warehouse["name"],
                "sourceAddress": warehouse["address"],
                "leadTimeDays": lead_time_days,
                "estimatedDeliveryDate": _estimate_delivery_date(requested_date, lead_time_days),
                "incoterm": incoterm,
                "reason": "Warehouse selected for best balance of ATP availability, lane proximity, and delivery certainty.",
            },
            "substitute": {
                "sku": catalog_entry["substitute_sku"],
                "reason": catalog_entry["substitute_reason"],
            },
            "blockers": line_blockers,
        })

    primary_item = materialized_items[0]
    payload = {
        "status": "success",
        "mode": "fallback_sap_joule",
        "scenarioType": scenario_type,
        "requestContext": {
            "customer": customer_name,
            "destinationCity": city.title(),
            "destinationCountry": country,
            "incoterm": incoterm,
            "requestedDeliveryDate": requested_date.isoformat() if requested_date else None,
            "orderReference": order_reference,
        },
        "inventoryAssessment": materialized_items,
        "sourcingDecision": {
            "selectedPlantCode": primary_item["sourcing"]["selectedWarehouseCode"],
            "selectedPlantName": primary_item["sourcing"]["selectedWarehouseName"],
            "warehouseAddress": primary_item["sourcing"]["sourceAddress"],
            "reason": "Selected as the primary fulfilment node for the current request because it provides the strongest ATP and shortest reliable lead time.",
            "inventorySummary": {
                "availableToPromise": primary_item["inventory"]["availableToPromise"],
                "confirmedQuantity": primary_item["inventory"]["confirmedQuantity"],
                "remainingAfterCommit": primary_item["inventory"]["remainingAfterCommit"],
                "stockStatus": primary_item["inventory"]["stockStatus"],
            },
            "pricingSummary": {
                "unitPrice": primary_item["pricing"]["unitPrice"],
                "totalCost": round(total_cost, 2),
                "currency": "EUR",
            },
            "deliveryProposal": {
                "estimatedDeliveryDate": _estimate_delivery_date(requested_date, max_lead_time),
                "leadTimeDays": max_lead_time,
                "incoterm": incoterm,
                "destination": f"{city.title()}, {country}",
            },
            "lineItems": materialized_items,
        },
        "blockers": blockers,
        "globalNotes": global_notes,
        "assumptions": assumptions,
    }
    return payload


# =========================================================================
# HTTP Client Helpers
# =========================================================================

async def make_post_request(
    url: str,
    payload: Dict[str, Any],
    token: str,
    timeout: int = 30,
    ssl_verify: bool = True
) -> Dict[str, Any]:
    """
    Perform an async POST request with Bearer token authentication.

    Args:
        url: Full endpoint URL for the POST request
        payload: Dictionary containing the request body
        token: Bearer token for authentication
        timeout: Request timeout in seconds
        ssl_verify: Whether to verify SSL certificates

    Returns:
        Dictionary containing the JSON response

    Raises:
        Exception: If the request fails or response is not valid JSON
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    connector = TCPConnector(ssl=ssl_verify)
    timeout_config = aiohttp.ClientTimeout(total=timeout)

    try:
        async with ClientSession(connector=connector, timeout=timeout_config) as session:
            async with session.post(url, json=payload, headers=headers) as response:
                text = await response.text()

                # Parse JSON response
                try:
                    response_json = await response.json()
                except Exception as e:
                    logger.error(f"Invalid JSON response from {url}: {text}")
                    raise Exception(f"Response is not valid JSON: {text}") from e

                # Check for HTTP errors
                if response.status >= 400:
                    logger.error(f"POST request failed: {response.status} - {text}")
                    raise Exception(f"POST request failed: {response.status} {text}")

                logger.debug(f"POST request successful to {url}")
                return response_json

    except ClientError as e:
        logger.error(f"HTTP client error during POST to {url}: {str(e)}")
        raise Exception(f"HTTP client error: {str(e)}") from e
    except Exception as e:
        logger.error(f"Unexpected error during POST to {url}: {str(e)}")
        raise


async def make_get_request(
    url: str,
    token: str,
    timeout: int = 30,
    ssl_verify: bool = True
) -> Dict[str, Any]:
    """
    Perform an async GET request with Bearer token authentication.

    Args:
        url: Full endpoint URL for the GET request
        token: Bearer token for authentication
        timeout: Request timeout in seconds
        ssl_verify: Whether to verify SSL certificates

    Returns:
        Dictionary containing the JSON response

    Raises:
        Exception: If the request fails or response is not valid JSON
    """
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }

    connector = TCPConnector(ssl=ssl_verify)
    timeout_config = aiohttp.ClientTimeout(total=timeout)

    try:
        async with ClientSession(connector=connector, timeout=timeout_config) as session:
            async with session.get(url, headers=headers) as response:
                text = await response.text()

                # Parse JSON response
                try:
                    response_json = await response.json()
                except Exception as e:
                    logger.error(f"Invalid JSON response from {url}: {text}")
                    raise Exception(f"Response is not valid JSON: {text}") from e

                # Check for HTTP errors
                if response.status >= 400:
                    logger.error(f"GET request failed: {response.status} - {text}")
                    raise Exception(f"GET request failed: {response.status} {text}")

                logger.debug(f"GET request successful to {url}")
                return response_json

    except ClientError as e:
        logger.error(f"HTTP client error during GET to {url}: {str(e)}")
        raise Exception(f"HTTP client error: {str(e)}") from e
    except Exception as e:
        logger.error(f"Unexpected error during GET to {url}: {str(e)}")
        raise


# =========================================================================
# Response Parsing Helpers
# =========================================================================

def extract_json_from_markdown(content: str) -> Optional[Dict[str, Any]]:
    """
    Extract JSON content from markdown code blocks.

    SAP Joule often returns JSON wrapped in ```json ... ``` blocks.
    This function extracts and parses that JSON.

    Args:
        content: The message content that may contain markdown-wrapped JSON

    Returns:
        Parsed JSON dictionary if found, None otherwise
    """
    # Try to find JSON in markdown code blocks
    json_pattern = r'```json\s*\n(.*?)\n```'
    match = re.search(json_pattern, content, re.DOTALL)

    if match:
        json_str = match.group(1)
        try:
            return json.loads(json_str)
        except json.JSONDecodeError as e:
            logger.warning(f"Failed to parse JSON from markdown block: {e}")
            return None

    # Try to parse the entire content as JSON
    try:
        return json.loads(content)
    except json.JSONDecodeError:
        # Content is plain text, not JSON
        return None


def parse_message_thread_response(response: Dict[str, Any]) -> Dict[str, Any]:
    """
    Parse the SAP Joule message thread response into a structured format
    suitable for LLM analysis.

    Args:
        response: Raw API response from get_all_messages_in_thread

    Returns:
        Structured dictionary with:
        - message_count: Number of messages
        - messages: List of parsed messages with metadata and parsed content
        - latest_ai_message: The most recent AI response (if any)
        - latest_user_message: The most recent user message (if any)
        - conversation_summary: Brief summary for LLM context
    """
    messages = response.get("value", [])

    parsed_messages = []
    latest_ai_message = None
    latest_user_message = None

    for msg in messages:
        sender = msg.get("sender", "unknown")
        content = msg.get("content", "")

        # Extract JSON if present in content
        parsed_json = extract_json_from_markdown(content)

        parsed_msg = {
            "id": msg.get("ID"),
            "sender": sender,
            "type": msg.get("type"),
            "created_at": msg.get("createdAt"),
            "content": content,
            "parsed_json": parsed_json,  # Extracted structured data
            "has_structured_data": parsed_json is not None,
            "group_id": msg.get("group_ID")
        }

        parsed_messages.append(parsed_msg)

        # Track latest messages by sender
        if sender == "ai":
            latest_ai_message = parsed_msg
        elif sender == "user":
            latest_user_message = parsed_msg

    return {
        "status": "success",
        "message_count": len(messages),
        "messages": parsed_messages,
        "latest_ai_message": latest_ai_message,
        "latest_user_message": latest_user_message,
        "conversation_summary": _generate_conversation_summary(parsed_messages)
    }


def _generate_conversation_summary(messages: List[Dict[str, Any]]) -> str:
    """
    Generate a brief summary of the conversation for LLM context.

    Args:
        messages: List of parsed messages

    Returns:
        Summary string
    """
    user_msgs = [m for m in messages if m["sender"] == "user"]
    ai_msgs = [m for m in messages if m["sender"] == "ai"]

    return (
        f"Conversation has {len(user_msgs)} user message(s) and "
        f"{len(ai_msgs)} AI response(s). "
        f"Latest AI response contains {'structured data' if ai_msgs and ai_msgs[-1]['has_structured_data'] else 'text only'}."
    )


def extract_rfq_decision(parsed_response: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """
    Extract the sourcing decision from the latest AI message.

    This is a helper to quickly get the key decision data from the RFQ response.

    Args:
        parsed_response: Output from parse_message_thread_response

    Returns:
        Dictionary with sourcing decision details, or None if not found
    """
    latest_ai = parsed_response.get("latest_ai_message")
    if not latest_ai or not latest_ai.get("parsed_json"):
        return None

    json_data = latest_ai["parsed_json"]

    # Extract key decision points
    sourcing_decision = json_data.get("sourcingDecision", {})
    pricing = sourcing_decision.get("pricingSummary", {})
    delivery = sourcing_decision.get("deliveryProposal", {})

    return {
        "selected_warehouse": sourcing_decision.get("selectedPlantName"),
        "warehouse_address": sourcing_decision.get("warehouseAddress"),
        "reason": sourcing_decision.get("reason"),
        "estimated_delivery_date": delivery.get("estimatedDeliveryDate"),
        "total_cost": pricing.get("totalCost"),
        "currency": pricing.get("currency"),
        "full_sourcing_data": sourcing_decision
    }


def check_if_followup_needed(parsed_response: Dict[str, Any]) -> Dict[str, Any]:
    """
    Analyze the latest AI response to determine if a follow-up is needed.

    Args:
        parsed_response: Output from parse_message_thread_response

    Returns:
        Dictionary with:
        - needs_followup: Boolean indicating if follow-up is needed
        - reason: Why follow-up is needed
        - suggested_action: What should be done next
    """
    latest_ai = parsed_response.get("latest_ai_message")
    if not latest_ai:
        return {
            "needs_followup": False,
            "reason": "No AI response yet",
            "suggested_action": "Wait for AI response"
        }

    content = latest_ai.get("content", "").lower()
    has_structured_data = latest_ai.get("has_structured_data", False)

    # Check for questions or requests in the content
    question_indicators = [
        "?",
        "please confirm",
        "please provide",
        "do you want",
        "would you like",
        "which option",
        "select"
    ]

    has_question = any(indicator in content for indicator in question_indicators)

    if has_question and not has_structured_data:
        return {
            "needs_followup": True,
            "reason": "AI is asking a question or requesting clarification",
            "suggested_action": "Analyze the question and provide appropriate response",
            "ai_content": latest_ai.get("content")
        }

    if has_structured_data:
        # Check if it's a complete RFQ response
        parsed_json = latest_ai.get("parsed_json", {})
        if "sourcingDecision" in parsed_json:
            return {
                "needs_followup": False,
                "reason": "Complete RFQ response received with sourcing decision",
                "suggested_action": "Present results to user",
                "rfq_complete": True
            }

    return {
        "needs_followup": False,
        "reason": "Response appears complete",
        "suggested_action": "Review content and determine next steps"
    }


def parse_thread_id(response: Dict[str, Any]) -> str:
    """
    Parse the SAP Joule thread creation response and extract the thread ID.

    Args:
        response: The response dictionary from the create_joule_thread API call

    Returns:
        The newly created thread's ID as a string

    Raises:
        ValueError: If the response does not contain a valid 'ID' field
    """
    thread_id = response.get("ID")
    if not thread_id or not isinstance(thread_id, str):
        logger.error(f"Thread ID not found or invalid in response: {response}")
        raise ValueError(f"Thread ID not found or invalid in response: {response}")

    logger.info(f"Successfully parsed thread ID: {thread_id}")
    return thread_id


# ============================================================================
# TOOL FUNCTIONS
# ============================================================================

# =========================================================================
# SAP Joule Agent Tool: Get authentication token for BAF APIs
# =========================================================================

async def get_authentication_token_for_BAF(
    tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, str]:
    """
    Retrieve a new bearer token using OAuth2 client credentials flow.

    This tool obtains an authentication token required for all subsequent SAP Joule API calls.
    The token is valid for 60 minutes.

    Args:
        tool_config: The SAM tool context containing configuration

    Returns:
        Dictionary with 'token' key containing the access token string

    Raises:
        Exception: If the token request fails or response is invalid
    """

    # Extract configuration
    token_url = tool_config.get("token_url")
    client_id = tool_config.get("client_id")
    client_secret = tool_config.get("client_secret")
    request_timeout = tool_config.get("request_timeout", 30)
    ssl_verify = tool_config.get("ssl_verify", True)

    # Validate required parameters
    if not all([token_url, client_id, client_secret]):
        raise ValueError("Missing required authentication configuration: token_url, client_id, or client_secret")

    headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }
    data = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret
    }

    connector = TCPConnector(ssl=ssl_verify)
    timeout_config = aiohttp.ClientTimeout(total=request_timeout)

    try:
        async with ClientSession(connector=connector, timeout=timeout_config) as session:
            async with session.post(token_url, headers=headers, data=data) as response:
                text = await response.text()

                # Parse JSON response
                try:
                    token_response = await response.json()
                except Exception as e:
                    logger.error(f"Token response is not valid JSON: {text}")
                    raise Exception(f"Token response is not valid JSON: {text}") from e

                # Check for HTTP errors
                if response.status >= 400:
                    logger.error(f"Token request failed: {response.status} - {text}")
                    raise Exception(f"Token request failed: {response.status} {text}")

                # Extract access token
                if "access_token" not in token_response:
                    logger.error(f"No access_token in response: {token_response}")
                    raise Exception(f"No access_token in response: {token_response}")

                logger.info("Successfully retrieved bearer token")
                return {
                    "token": token_response["access_token"],
                    "status": "success",
                    "message": "Authentication token retrieved successfully. Valid for 60 minutes."
                }

    except ClientError as e:
        logger.error(f"HTTP client error during token request: {str(e)}")
        raise Exception(f"Bearer token request failed: {str(e)}") from e
    except Exception as e:
        logger.error(f"Unexpected error during token request: {str(e)}")
        raise


# =========================================================================
# SAP Joule Agent Thread Creation Tool
# =========================================================================

async def create_Joule_thread_for_RFQ_Request(
    sku: str,
    quantity: int,
    token: str,
    tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, str]:
    """
    Create a new thread/conversation for a given SAP Joule agent and return the thread ID.

    This function:
      - Constructs the thread name from SKU and quantity using the configured template
      - Invokes the POST API to create the thread
      - Parses the response to extract and return the thread ID

    Args:
        sku: The SKU for which the quote is requested
        quantity: The quantity for the quote
        token: Bearer token for authentication (from get_authentication_token_for_BAF)
        tool_config: The SAM tool context containing configuration

    Returns:
        Dictionary with 'thread_id' and status information

    Raises:
        Exception: If the API call fails or response is invalid
    """

    # Extract configuration
    base_url = tool_config.get("base_url")
    agent_id = tool_config.get("agent_id")
    thread_name_template = tool_config.get("thread_name_template", "RFQ for SKU: {sku}, quantity: {quantity}")
    request_timeout = tool_config.get("request_timeout", 30)
    ssl_verify = tool_config.get("ssl_verify", True)

    logger.info(f"BaseUrl: {base_url}, agent_id: {agent_id}")


    # Validate required parameters
    if not all([base_url, agent_id]):
        logger.error(f"BaseUrl: {base_url}, agent_id: {agent_id}")
        raise ValueError("Missing required configuration: base_url or agent_id")

    try:
        thread_name = thread_name_template.format(sku=sku, quantity=quantity)
    except Exception as e:
        logger.error(f"Failed to format thread name template: {e}")
        raise Exception(f"Failed to format thread name template: {e}") from e

    payload = {"name": thread_name}
    url = f"{base_url}/agent-controller/v1/Agents({agent_id})/threads"

    logger.info(f"Creating Joule thread for SKU: {sku}, quantity: {quantity}")
    response = await make_post_request(url, payload, token, request_timeout, ssl_verify)
    thread_id = parse_thread_id(response)

    return {
        "thread_id": thread_id,
        "status": "success",
        "message": f"Thread created successfully for SKU: {sku}, quantity: {quantity}",
        "thread_name": thread_name
    }


# =========================================================================
# SAP Joule Agent Tool: send_RFQ_request_to_thread
# =========================================================================

async def send_RFQ_request_to_thread(
    thread_id: str,
    sku: str,
    quantity: int,
    delivery_address: str,
    token: str,
    tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Submit an RFQ message to a given threadId for the specified agent.

    The message payload template is fetched from the configuration and placeholders are substituted.

    Args:
        thread_id: The thread ID where the message should be sent (from create_Joule_thread_for_RFQ_Request)
        sku: The SKU for which the RFQ is requested
        quantity: The quantity for the RFQ
        delivery_address: The delivery address for the product
        token: Bearer token for authentication
        tool_config: The SAM tool context containing configuration

    Returns:
        Dictionary containing the API response, including messageId and groupId

    Raises:
        Exception: If the API call fails or response is invalid
    """

    # Extract configuration
    base_url = tool_config.get("base_url")
    agent_id = tool_config.get("agent_id")
    message_template = tool_config.get(
        "message_template",
        (
            "I would like to create a RFQ for SKU: {sku}, quantity: {quantity}. "
            "The delivery address is: {delivery_address}. "
            "Give me availability, stocking, lead times and costing for the product across all warehouses which can deliver to this location. "
            "Choose the warehouse with the lowest lead time and cost as the sourcing location and give me the full address of the warehouse. "
            "Return the results in a proper JSON format for integration."
        )
    )
    request_timeout = tool_config.get("request_timeout", 30)
    ssl_verify = tool_config.get("ssl_verify", True)

    # Validate required parameters
    if not all([base_url, agent_id]):
        raise ValueError("Missing required configuration: base_url or agent_id")

    # Format message using template
    try:
        message = message_template.format(sku=sku, quantity=quantity, delivery_address=delivery_address)
    except Exception as e:
        logger.error(f"Failed to substitute message template: {e}")
        raise Exception(f"Failed to substitute message template: {e}") from e

    payload = {
        "message": message,
        "callbackTarget": ""
    }

    url = f"{base_url}/agent-controller/v1/Agents({agent_id})/threads({thread_id})/AgentControllerService.invoke"

    logger.info(f"Sending RFQ message to thread {thread_id} for SKU: {sku}, quantity: {quantity}")
    response = await make_post_request(url, payload, token, request_timeout, ssl_verify)

    # Validate response structure
    if not isinstance(response, dict) or "messageId" not in response:
        logger.error(f"Unexpected response structure: {response}")
        raise Exception(f"Unexpected response structure: {response}")

    logger.info(f"Message sent successfully. MessageId: {response.get('messageId')}, GroupId: {response.get('groupId')}")

    return {
        "status": "success",
        "message_id": response.get("messageId"),
        "group_id": response.get("groupId"),
        "message": f"RFQ request sent successfully for SKU: {sku}, quantity: {quantity}"
    }


# =========================================================================
# SAP Joule Agent Tool: send_reply_message_to_thread
# =========================================================================

async def send_reply_message_to_thread(
    thread_id: str,
    reply_message: str,
    token: str,
    tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Posts a reply message to the thread based on the previous query from the SAP Joule Agent.

    Use this tool when the SAP Joule Agent asks follow-up questions that require a response.
    The default values should be used when possible, unless the user specifies otherwise.
    For values which need an explicit answer, infer them from the product, RFQ request, and other available information.

    Args:
        thread_id: The thread ID where the message should be sent (from create_Joule_thread_for_RFQ_Request)
        reply_message: The reply message to send to the SAP Joule Agent
        token: Bearer token for authentication
        tool_config: The SAM tool context containing configuration

    Returns:
        Dictionary containing the API response, including messageId and groupId

    Raises:
        Exception: If the API call fails or response is invalid
    """
     # Extract configuration
    base_url = tool_config.get("base_url")
    agent_id = tool_config.get("agent_id")
    request_timeout = tool_config.get("request_timeout", 30)
    ssl_verify = tool_config.get("ssl_verify", True)

    # Validate required parameters
    if not all([base_url, agent_id]):
        raise ValueError("Missing required configuration: base_url or agent_id")

    if not reply_message:
        raise ValueError("reply_message parameter is required and cannot be empty")

    payload = {
        "message": reply_message,
        "callbackTarget": ""
    }

    url = f"{base_url}/agent-controller/v1/Agents({agent_id})/threads({thread_id})/AgentControllerService.invoke"

    logger.info(f"Sending reply message to thread {thread_id}")
    response = await make_post_request(url, payload, token, request_timeout, ssl_verify)

    # Validate response structure
    if not isinstance(response, dict) or "messageId" not in response:
        logger.error(f"Unexpected response structure: {response}")
        raise Exception(f"Unexpected response structure: {response}")

    logger.info(f"Reply sent successfully. MessageId: {response.get('messageId')}, GroupId: {response.get('groupId')}")

    return {
        "status": "success",
        "message_id": response.get("messageId"),
        "group_id": response.get("groupId"),
        "message": "Reply message sent successfully"
    }


# =========================================================================
# SAP Joule Agent Tool: Get Thread Messages
# =========================================================================

async def get_all_messages_in_thread(
    thread_id: str,
    token: str,
    tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Retrieve all messages for a given thread from the SAP Joule Agent API.

    It parses the response to extract structured data from
    the conversation, making it easier for the LLM to analyze and decide next steps.

    Use this tool to check the responses from the SAP Joule Agent and determine
    if follow-up actions or replies are needed.

    Args:
        thread_id: The thread ID for which messages are to be retrieved
        token: Bearer token for authentication
        tool_config: The SAM tool configuration dictionary

    Returns:
        Dictionary containing:
        - status: Success/error status
        - thread_id: The thread ID
        - message_count: Number of messages in thread
        - messages: Array of parsed messages with extracted JSON content
        - latest_ai_message: Most recent AI response with parsed data
        - latest_user_message: Most recent user message
        - conversation_summary: Brief summary of the conversation
        - followup_analysis: Whether follow-up is needed and why
        - rfq_decision: Extracted sourcing decision (if available)

    Raises:
        Exception: If the API call fails or response is invalid
    """
    # Extract configuration
    base_url = tool_config.get("base_url")
    agent_id = tool_config.get("agent_id")
    request_timeout = tool_config.get("request_timeout", 30)
    ssl_verify = tool_config.get("ssl_verify", True)

    # Validate required parameters
    if not all([base_url, agent_id]):
        raise ValueError("Missing required configuration: base_url or agent_id")

    url = f"{base_url}/agent-controller/v1/Agents({agent_id})/threads({thread_id})/messages"

    logger.info(f"Retrieving messages for thread {thread_id}")
    response = await make_get_request(url, token, request_timeout, ssl_verify)

    # Validate response structure
    if not isinstance(response, dict) or 'value' not in response:
        logger.error(f"Unexpected response structure: {response}")
        raise Exception(f"Unexpected response structure: {response}")

    # Parse the response for intelligent analysis
    parsed_response = parse_message_thread_response(response)

    # Analyze if follow-up is needed
    followup_analysis = check_if_followup_needed(parsed_response)

    # Extract RFQ decision if available
    rfq_decision = extract_rfq_decision(parsed_response)

    logger.info(
        f"Successfully retrieved {parsed_response['message_count']} messages. "
        f"Follow-up needed: {followup_analysis['needs_followup']}"
    )

    # Return comprehensive analysis for the LLM
    return {
        "status": "success",
        "thread_id": thread_id,
        "message_count": parsed_response["message_count"],
        "messages": parsed_response["messages"],
        "latest_ai_message": parsed_response["latest_ai_message"],
        "latest_user_message": parsed_response["latest_user_message"],
        "conversation_summary": parsed_response["conversation_summary"],
        "followup_analysis": followup_analysis,
        "rfq_decision": rfq_decision
    }


async def run_mock_joule_assessment(
    request_text: str,
    tool_context: Optional[Any] = None,
    tool_config: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """
    Generate a deterministic SAP Joule-style sourcing assessment for demo scenarios.

    This tool is intended as a stable fallback when the live SAP Joule APIs are not
    reliable enough for demo execution. It accepts the raw user or peer-agent request
    text, extracts the relevant RFQ/order context, and returns a structured response
    that mirrors the fields the rest of the quote and operations flows expect.

    Args:
        request_text: Full user or peer-agent request text.
        tool_context: Optional SAM tool context (unused).
        tool_config: Optional tool configuration (unused).

    Returns:
        Structured SAP-equivalent sourcing decision payload.
    """
    if not request_text or not request_text.strip():
        raise ValueError("request_text is required")

    payload = _build_mock_joule_payload(request_text)
    payload["requestId"] = str(uuid.uuid4())
    payload["generatedAt"] = datetime.utcnow().isoformat(timespec="seconds") + "Z"
    payload["has_tool_context"] = tool_context is not None

    logger.info(
        "Generated fallback SAP Joule assessment for %s line item(s), scenario=%s",
        len(payload.get("inventoryAssessment", [])),
        payload.get("scenarioType"),
    )
    return payload

# End of tools.py
