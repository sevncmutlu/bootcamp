from pydantic import Field, JsonValue

from maki.api.dependencies import JobAcceptor
from maki.common.models import ApiModel
from maki.jobs.models import JobKind


class AcceptedJob(ApiModel):
    job_id: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    status_url: str
    retry_after_seconds: int = Field(default=2, ge=1, le=60)


async def accept_job(
    *,
    service: JobAcceptor,
    kind: JobKind,
    payload: dict[str, JsonValue],
    owner_id: str,
    idempotency_key: str,
) -> AcceptedJob:
    job = await service.accept(
        kind,
        payload,
        owner_id,
        idempotency_key,
    )
    return AcceptedJob(
        job_id=job.job_id,
        status_url=f"/api/v1/jobs/{job.job_id}",
    )
