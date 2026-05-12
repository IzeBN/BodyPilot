from pydantic import BaseModel, Field
from typing import Optional


class EquipmentItem(BaseModel):
    category_id: int = Field(..., description="Equipment category ID")
    item_id: int = Field(..., description="Equipment item ID")
    option_id: Optional[int] = Field(None, description="Optional equipment option/variant ID")


class UpdateEquipmentRequest(BaseModel):
    equipment: list[EquipmentItem] = Field(
        ...,
        description=(
            "Full replacement of user's equipment list. "
            "All existing entries are removed and replaced with this list."
        ),
    )


# ── Response models ────────────────────────────────────────────────────────────

class EquipmentOptionResponse(BaseModel):
    id: int = Field(..., description="Option ID")
    name: str = Field(..., description="Option name (e.g. weight variant)")


class EquipmentCatalogItem(BaseModel):
    id: int = Field(..., description="Item ID")
    name: str = Field(..., description="Item name")
    description: Optional[str] = Field(None, description="Item description")
    image_url: Optional[str] = Field(None, description="Item image URL")
    options: list[EquipmentOptionResponse] = Field(default_factory=list, description="Available options/variants")


class EquipmentCategoryResponse(BaseModel):
    id: int = Field(..., description="Category ID")
    name: str = Field(..., description="Category name")
    items: list[EquipmentCatalogItem] = Field(..., description="Items in this category")


class UserEquipmentItemResponse(BaseModel):
    category_id: int = Field(..., description="Category ID")
    category_name: str = Field(..., description="Category name")
    item_id: int = Field(..., description="Item ID")
    item_name: str = Field(..., description="Item name")
    option_id: Optional[int] = Field(None, description="Selected option ID")
    option_name: Optional[str] = Field(None, description="Selected option name")
