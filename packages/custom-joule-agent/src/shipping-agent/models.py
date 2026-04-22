"""
Pydantic models for ShipEngine API request validation.
Ensures all required fields are present and correctly typed.
"""

from pydantic import BaseModel
from typing import List, Optional

class Address(BaseModel):
    """Shipping or receiving address for a shipment."""
    name: str
    phone: str
    company_name: Optional[str]
    address_line1: str
    city_locality: str
    state_province: str
    postal_code: str
    country_code: str
    address_residential_indicator: str

class Weight(BaseModel):
    """Package weight with value and unit."""
    value: float
    unit: str

class Package(BaseModel):
    """Package in a shipment with code and weight."""
    package_code: str
    weight: Weight

class Shipment(BaseModel):
    """Shipment details including addresses and packages."""
    validate_address: Optional[str]
    ship_to: Address
    ship_from: Address
    packages: List[Package]

class RateOptions(BaseModel):
    """Options for rate calculation."""
    carrier_ids: List[str]

class RateRequest(BaseModel):
    """Top-level request model for ShipEngine rate calculation."""
    rate_options: RateOptions
    shipment: Shipment
