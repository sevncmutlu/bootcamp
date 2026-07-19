from typing import Annotated

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status

from maki.api.dependencies import (
    IdempotencyHeader,
    JobAcceptor,
    ReceiptIngress,
    authenticated_subject,
    receipt_ingress,
    receipt_job_acceptor,
)
from maki.api.routes.common import AcceptedJob, accept_job
from maki.jobs.models import JobKind

router = APIRouter(prefix="/api/v1/receipts", tags=["fiş"])
_MAXIMUM_IMAGE_BYTES = 8 * 1024 * 1024
_ALLOWED_MEDIA_TYPES = frozenset({"image/jpeg", "image/png"})


@router.post(
    "/jobs",
    operation_id="receipt_job_create",
    description="Fiş görselini kısa ömürlü OCR kuyruğuna kabul eder.",
    status_code=status.HTTP_202_ACCEPTED,
)
async def create_receipt_job(
    file: Annotated[UploadFile, File()],
    idempotency_key: IdempotencyHeader,
    owner_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[JobAcceptor, Depends(receipt_job_acceptor)],
    ingress: Annotated[ReceiptIngress, Depends(receipt_ingress)],
) -> AcceptedJob:
    media_type = file.content_type or ""
    if media_type not in _ALLOWED_MEDIA_TYPES:
        raise HTTPException(
            status_code=422,
            detail="Yalnızca JPEG veya PNG fiş görseli kabul edilir.",
        )
    content = await file.read(_MAXIMUM_IMAGE_BYTES + 1)
    await file.close()
    if not content or len(content) > _MAXIMUM_IMAGE_BYTES:
        raise HTTPException(
            status_code=422,
            detail="Fiş görseli boş veya 8 MiB sınırını aşıyor.",
        )
    object_ref = await ingress.put(
        owner_id=owner_id,
        content=content,
        media_type=media_type,
    )
    return await accept_job(
        service=service,
        kind=JobKind.RECEIPT,
        payload={
            "object_ref": object_ref,
            "media_type": media_type,
        },
        owner_id=owner_id,
        idempotency_key=idempotency_key,
    )
