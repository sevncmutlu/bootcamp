from typing import Annotated

from fastapi import APIRouter, Depends, status
from pydantic import Field

from maki.api.dependencies import (
    IdempotencyHeader,
    JobAcceptor,
    authenticated_subject,
    job_acceptor,
)
from maki.api.routes.common import AcceptedJob, accept_job
from maki.common.models import ApiModel
from maki.forecast.models import RelativeSeries
from maki.jobs.models import JobKind

router = APIRouter(prefix="/api/v1/forecasts", tags=["tahmin"])


class ForecastJobRequest(ApiModel):
    series: RelativeSeries
    horizon: int = Field(default=7, ge=1, le=90)


@router.post(
    "/jobs",
    operation_id="forecast_job_create",
    description="Göreli zaman serisini tahmin kuyruğuna kabul eder.",
    status_code=status.HTTP_202_ACCEPTED,
)
async def create_forecast_job(
    request: ForecastJobRequest,
    idempotency_key: IdempotencyHeader,
    owner_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[JobAcceptor, Depends(job_acceptor)],
) -> AcceptedJob:
    return await accept_job(
        service=service,
        kind=JobKind.FORECAST,
        payload=request.model_dump(mode="json"),
        owner_id=owner_id,
        idempotency_key=idempotency_key,
    )
