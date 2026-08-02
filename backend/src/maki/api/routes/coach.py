from typing import Annotated

from fastapi import APIRouter, Depends, Header, Request, status

from maki.api.dependencies import (
    IdempotencyHeader,
    JobAcceptor,
    authenticated_subject,
    coach_job_acceptor,
    container_from_request,
)
from maki.api.routes.common import AcceptedJob, accept_job
from maki.coach.models import CoachQuery
from maki.jobs.models import JobKind
from maki.privacy.scrubber import TextScrubber

router = APIRouter(prefix="/api/v1/coach", tags=["koç"])
_SCRUBBER = TextScrubber()


@router.post(
    "/queries",
    operation_id="coach_query_create",
    description="Temizlenmiş tek koç sorusunu iş kuyruğuna kabul eder.",
    status_code=status.HTTP_202_ACCEPTED,
)
async def create_coach_query(
    request: Request,
    query: CoachQuery,
    idempotency_key: IdempotencyHeader,
    owner_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[JobAcceptor, Depends(coach_job_acceptor)],
    gemini_api_key: Annotated[
        str | None,
        Header(alias="X-Maki-Gemini-Key", min_length=20, max_length=256),
    ] = None,
) -> AcceptedJob:
    cleaned = query.model_copy(
        update={"question": _SCRUBBER.scrub(query.question).text},
    )
    gateway = container_from_request(request).coach_request_acceptor
    if gateway is not None:
        job = await gateway.accept_coach(
            query=cleaned,
            owner_id=owner_id,
            idempotency_key=idempotency_key,
            request_api_key=gemini_api_key,
        )
        return AcceptedJob(
            job_id=job.job_id,
            status_url=f"/api/v1/jobs/{job.job_id}",
            retry_after_seconds=1,
        )
    return await accept_job(
        service=service,
        kind=JobKind.COACH,
        payload=cleaned.model_dump(mode="json"),
        owner_id=owner_id,
        idempotency_key=idempotency_key,
    )
