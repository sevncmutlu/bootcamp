from typing import Annotated

from fastapi import APIRouter, Depends, status

from maki.api.dependencies import (
    IdempotencyHeader,
    JobAcceptor,
    authenticated_subject,
    coach_job_acceptor,
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
    query: CoachQuery,
    idempotency_key: IdempotencyHeader,
    owner_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[JobAcceptor, Depends(coach_job_acceptor)],
) -> AcceptedJob:
    cleaned = query.model_copy(
        update={"question": _SCRUBBER.scrub(query.question).text},
    )
    return await accept_job(
        service=service,
        kind=JobKind.COACH,
        payload=cleaned.model_dump(mode="json"),
        owner_id=owner_id,
        idempotency_key=idempotency_key,
    )
