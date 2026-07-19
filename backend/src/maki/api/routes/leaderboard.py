from typing import Annotated

from fastapi import APIRouter, Depends
from pydantic import Field

from maki.api.dependencies import (
    IdempotencyHeader,
    LeaderboardPort,
    authenticated_subject,
    leaderboard,
)
from maki.common.models import ApiModel
from maki.leaderboard.models import CohortKey, CohortPercentile

router = APIRouter(prefix="/api/v1/leaderboard", tags=["liderlik"])


class LeaderboardRequest(ApiModel):
    cohort: CohortKey
    score_basis_points: int = Field(ge=0, le=10_000)


@router.post(
    "/percentiles",
    operation_id="leaderboard_percentile_create",
    description="K-anonim kohort yüzdelik dilimini hesaplar.",
)
async def create_percentile(
    request: LeaderboardRequest,
    _idempotency_key: IdempotencyHeader,
    owner_id: Annotated[str, Depends(authenticated_subject)],
    service: Annotated[LeaderboardPort, Depends(leaderboard)],
) -> CohortPercentile:
    return await service.percentile(
        cohort=request.cohort,
        score_basis_points=request.score_basis_points,
        subject_id=owner_id,
    )
