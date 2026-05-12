from fastapi import APIRouter, Depends
from app.dependencies import get_equipment_service, get_current_user_id, get_lang
from app.models.equipment import (
    UpdateEquipmentRequest,
    EquipmentCategoryResponse, UserEquipmentItemResponse,
)
from app.models.common import OkResponse
from app.services.equipment_service import EquipmentService

router = APIRouter(prefix="/equipment", tags=["equipment"])


@router.get(
    "/",
    response_model=list[EquipmentCategoryResponse],
    summary="Get equipment catalog",
    description=(
        "Returns the full equipment catalog grouped by category, each with items and options. "
        "Use to render the equipment selection screen. Supports i18n via Accept-Language."
    ),
)
async def get_catalog(
    lang: str = Depends(get_lang),
    service: EquipmentService = Depends(get_equipment_service),
):
    return await service.get_catalog(lang)


@router.get(
    "/user",
    response_model=list[UserEquipmentItemResponse],
    summary="Get user's equipment",
    description="Returns the equipment items selected by the current user.",
)
async def get_user_equipment(
    lang: str = Depends(get_lang),
    user_id: int = Depends(get_current_user_id),
    service: EquipmentService = Depends(get_equipment_service),
):
    return await service.get_user_equipment(user_id, lang)


@router.put(
    "/user",
    response_model=OkResponse,
    summary="Update user's equipment",
    description=(
        "Full replacement of the user's equipment list. "
        "All previous entries are deleted and replaced with the provided list."
    ),
)
async def update_user_equipment(
    body: UpdateEquipmentRequest,
    user_id: int = Depends(get_current_user_id),
    service: EquipmentService = Depends(get_equipment_service),
):
    await service.update_user_equipment(user_id, [item.model_dump() for item in body.equipment])
    return OkResponse()
