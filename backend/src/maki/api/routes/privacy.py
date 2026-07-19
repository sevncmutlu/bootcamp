from typing import Annotated

from fastapi import APIRouter, Depends, Response

from maki.api.dependencies import (
    DataExporterPort,
    DeletionServicePort,
    IdempotencyHeader,
    authenticated_subject,
    data_exporter,
    deletion_service,
)
from maki.privacy.deletion import DeletionCounts
from maki.privacy.export import DataExport

router = APIRouter(prefix="/api/v1/privacy", tags=["gizlilik"])


@router.get(
    "/exports",
    operation_id="privacy_export_get",
    description="Oturum sahibine bağlı sunucu kayıtlarını güvenli biçimde dışa aktarır.",
)
async def export_data(
    response: Response,
    subject_id: Annotated[str, Depends(authenticated_subject)],
    exporter: Annotated[DataExporterPort, Depends(data_exporter)],
) -> DataExport:
    _disable_caching(response)
    return await exporter.export(subject_id=subject_id)


@router.delete(
    "/data",
    operation_id="privacy_data_delete",
    description="Oturum sahibine bağlı kayıtları siler veya geri bağlanamaz hâle getirir.",
)
async def delete_data(
    response: Response,
    _idempotency_key: IdempotencyHeader,
    subject_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[DeletionServicePort, Depends(deletion_service)],
) -> DeletionCounts:
    _disable_caching(response)
    return await service.delete(subject_id=subject_id)


def _disable_caching(response: Response) -> None:
    response.headers["Cache-Control"] = "no-store"
    response.headers["Pragma"] = "no-cache"
