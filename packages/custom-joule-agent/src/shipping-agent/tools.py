"""
Tools module for Shipping Agent.
Provides the tool interface for LLM to request shipping rates.

Following Solace Agent Mesh architecture:
- Tools contain business logic directly (no separate service layer)
- Configuration accessed via tool_config parameter (injected by framework)
- Helper functions used for code organization within this module
"""

import logging
from typing import Any, Dict, Optional

import aiohttp
import json
from pydantic import ValidationError

from google.adk.tools import ToolContext
try:
    from .models import RateRequest
except ImportError:
    # Supports direct module loading when component_base_path points to this folder.
    from models import RateRequest

log = logging.getLogger(__name__)

SHIPENGINE_API_URL = "https://api.shipengine.com/v1/rates"


# ============================================================================
# HELPER FUNCTIONS (Internal to this module)
# ============================================================================

def _build_ship_from_address(tool_config: Dict[str, Any],
                             ship_from_address_line1: str,
                             ship_from_city_locality: str,
                             ship_from_state_province: str,
                             ship_from_postal_code: str,
                             ship_from_country_code: str) -> dict:
    """
    Build ship_from address dictionary from tool configuration.
    Static values are taken from tool_config, while dynamic values are passed as parameters.

    Args:
        tool_config: Configuration dictionary injected by framework
        ship_from_address_line1: Street address of the sender
        ship_from_city_locality: City of the sender
        ship_from_state_province: State/province of the sender
        ship_from_postal_code: Postal code of the sender
        ship_from_country_code: Country code of the sender

    Returns:
        Ship from address dictionary
    """
    residential_indicator = tool_config.get('ship_from_address_residential_indicator', 'no')
    if isinstance(residential_indicator, bool):
        residential_indicator = "yes" if residential_indicator else "no"

    return {
        "name": tool_config.get('ship_from_name', ''),
        "phone": tool_config.get('ship_from_phone', ''),
        "company_name": tool_config.get('ship_from_company_name', ''),
        "address_residential_indicator": residential_indicator,
        "address_line1": ship_from_address_line1,
        "city_locality": ship_from_city_locality,
        "state_province": ship_from_state_province,
        "postal_code": ship_from_postal_code,
        "country_code": ship_from_country_code
    }


def _build_rates_request(
        carrier_ids: list,
        ship_from: dict,
        ship_to: dict,
        package_code: str,
        weight_value: float,
        weight_unit: str,
        validate_address: str = "no_validation"
) -> dict:
    """
    Build the request payload for ShipEngine API.

    Args:
        carrier_ids: List of carrier IDs
        ship_from: Sender address dictionary
        ship_to: Recipient address dictionary
        package_code: Package type code
        weight_value: Package weight value
        weight_unit: Weight unit
        validate_address: Address validation mode

    Returns:
        Request payload dictionary
    """
    return {
        "rate_options": {
            "carrier_ids": carrier_ids
        },
        "shipment": {
            "validate_address": validate_address,
            "ship_to": ship_to,
            "ship_from": ship_from,
            "packages": [
                {
                    "package_code": package_code,
                    "weight": {
                        "value": weight_value,
                        "unit": weight_unit
                    }
                }
            ]
        }
    }


async def _call_shipengine_api(request_payload: dict, api_key: str) -> dict:
    """
    Calls the ShipEngine Rates API to retrieve shipping rates.

    Args:
        request_payload: The request body matching RateRequest model
        api_key: ShipEngine API key

    Returns:
        dict: The parsed JSON response from ShipEngine

    Raises:
        ValueError: For invalid requests or bad request responses
        PermissionError: For unauthorized requests
        FileNotFoundError: For not found errors
        RuntimeError: For server errors
    """
    log.info(f"Request Payload here: {request_payload}")

    if not api_key:
        raise ValueError("ShipEngine API key must be provided.")

    # Validate request payload
    try:
        RateRequest.parse_obj(request_payload)
    except ValidationError as ve:
        log.error(f"Request payload validation error: {ve}")
        raise ValueError(f"Invalid request payload: {ve}")

    headers = {
        "Content-Type": "application/json",
        "API-Key": api_key,
    }
    async with aiohttp.ClientSession(connector=aiohttp.TCPConnector(ssl=False)) as session:
        try:
            async with session.post(SHIPENGINE_API_URL, json=request_payload, headers=headers) as resp:
                status = resp.status
                text = await resp.text()
                try:
                    response_json = json.loads(text)
                except Exception as e:
                    log.error(f"Response is not valid JSON: {e}\nRaw response: {text}")
                    raise ValueError("Response is not valid JSON")
                if status == 200:
                    log.info("ShipEngine API response received successfully")
                    return response_json
                elif status == 400:
                    log.error(f"Bad request: {response_json}")
                    raise ValueError(f"Bad request: {response_json}")
                elif status == 401:
                    log.error(f"Unauthorized: {response_json}")
                    raise PermissionError(f"Unauthorized: {response_json}")
                elif status == 404:
                    log.error(f"Not found: {response_json}")
                    raise FileNotFoundError(f"Not found: {response_json}")
                elif status >= 500:
                    log.error(f"Server error {status}: {response_json}")
                    raise RuntimeError(f"Server error {status}: {response_json}")
                else:
                    log.error(f"Unexpected status {status}: {response_json}")
                    raise Exception(f"Unexpected status {status}: {response_json}")
        except aiohttp.ClientResponseError as e:
            log.error(f"ShipEngine API error: {e.status} {e.message}")
            raise
        except Exception as e:
            log.error(f"Unexpected error calling ShipEngine API: {e}")
            raise


# ============================================================================
# TOOL FUNCTION
# ============================================================================

async def get_shipping_rates(
        ship_from_address_line1: str,
        ship_from_city_locality: str,
        ship_from_state_province: str,
        ship_from_postal_code: str,
        ship_from_country_code: str,

        ship_to_name: str,
        ship_to_phone: str,
        ship_to_address_line1: str,
        ship_to_city_locality: str,
        ship_to_state_province: str,
        ship_to_postal_code: str,
        ship_to_country_code: str,
        package_code: str,
        weight_value: float,
        weight_unit: str,
        ship_to_company_name: Optional[str] = None,
        ship_to_address_residential_indicator: str = "yes",
        validate_address: str = "no_validation",
        tool_config: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Gets shipping rates from ShipEngine API based on package and destination details.

    This tool function is called by the LLM through the ADKToolWrapper. The framework
    automatically injects tool_config parameters.

    Args:
        ship_from_address_line1: The street address of the warehouse from which the product will be shipped
        ship_from_city_locality: The locality of the warehouse from which the product will be shipped,
        ship_from_state_province: The province of the warehouse from which the product will be shipped,
        ship_from_postal_code: The postal code of the warehouse from which the product will be shipped
        ship_from_country_code: The country code of the warehouse from which the product will be shipped

        ship_to_name: Recipient's name
        ship_to_phone: Recipient's phone number
        ship_to_address_line1: Recipient's street address
        ship_to_city_locality: Recipient's city
        ship_to_state_province: Recipient's state/province
        ship_to_postal_code: Recipient's postal code
        ship_to_country_code: Recipient's country code (e.g., 'US', 'NL')
        package_code: Package type code (e.g., 'package', 'letter')
        weight_value: Weight of the package
        weight_unit: Unit of weight (e.g., 'kilogram', 'pound')
        ship_to_company_name: (Optional) Recipient's company name
        ship_to_address_residential_indicator: Whether address is residential
        validate_address: Address validation mode
        tool_config: Tool configuration from YAML (injected by framework)

    Returns:
        Dict containing shipping rates and options or error information
    """
    try:
        # Get configuration (injected by framework)
        config = tool_config or {}

        # Extract configuration values
        carrier_ids = config.get('carrier_ids', ["se-351051"])
        if isinstance(carrier_ids, str):
            carrier_ids = [carrier_ids]

        api_key = config.get('api_key', "")

        # Build ship_to address from parameters
        ship_to = {
            "name": ship_to_name,
            "phone": ship_to_phone,
            "company_name": ship_to_company_name or "",
            "address_line1": ship_to_address_line1,
            "city_locality": ship_to_city_locality,
            "state_province": ship_to_state_province,
            "postal_code": ship_to_postal_code,
            "country_code": ship_to_country_code,
            "address_residential_indicator": ship_to_address_residential_indicator
        }

        # Build ship_from address from configuration
        ship_from = _build_ship_from_address(config, ship_from_address_line1,
                                             ship_from_city_locality,
                                             ship_from_state_province,
                                             ship_from_postal_code,
                                             ship_from_country_code)

        log.info(f"Requesting shipping rates for {ship_to_name} to {ship_to_country_code}")

        # Build the request payload
        request_payload = _build_rates_request(
            carrier_ids=carrier_ids,
            ship_from=ship_from,
            ship_to=ship_to,
            package_code=package_code,
            weight_value=weight_value,
            weight_unit=weight_unit,
            validate_address=validate_address
        )

        log.info(f"Created request object: {json.dumps(request_payload, indent=2)}")

        # Call the ShipEngine API
        result = await _call_shipengine_api(request_payload, api_key)

        rates = result.get("rate_response", {}).get("rates", [])

        return {
            "status": "success",
            "rates": rates,
            "message": f"Found {len(rates)} shipping rate(s) for {ship_to_city_locality}, {ship_to_country_code}",
            "shipment_id": result.get("shipment_id"),
            "created_at": result.get("created_at")
        }

    except Exception as e:
        log.error(f"Error in get_shipping_rates tool: {e}", exc_info=True)
        return {
            "status": "error",
            "error": str(e),
            "message": f"Failed to get shipping rates: {str(e)}"
        }
