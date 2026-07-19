from typing import Annotated

from fastapi import APIRouter, Depends, Path

from maki.api.dependencies import (
    JobQuery,
    authenticated_subject,
    job_query,
)
from maki.jobs.query import JobStatusView

router = APIRouter(prefix="/api/v1/jobs", tags=["işler"])


@router.get(
    "/{job_id}",
    operation_id="job_status_get",
    description="Yalnız oturum sahibine ait iş durumunu döndürür.",
)
async def get_job_status(
    job_id: Annotated[
        str,
        Path(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$"),
    ],
    owner_id: Annotated[str, Depends(authenticated_subject)],
    query: Annotated[JobQuery, Depends(job_query)],
) -> JobStatusView:
    return await query.get(job_id=job_id, owner_id=owner_id)
