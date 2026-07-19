from datetime import UTC, datetime

from maki.leaderboard.models import (
    AgeBand,
    CohortKey,
    HouseholdBand,
    PercentileStatus,
)
from maki.leaderboard.service import LeaderboardService

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)
COHORT = CohortKey(
    age_band=AgeBand.AGE_25_34,
    household_band=HouseholdBand.ONE,
)


class MemoryLeaderboardRepository:
    def __init__(self, scores: tuple[int, ...]) -> None:
        self.scores = scores

    async def record_and_list(
        self,
        *,
        cohort_hash: str,
        subject_hash: str,
        score_basis_points: int,
        now: datetime,
        expires_at: datetime,
    ) -> tuple[int, ...]:
        del cohort_hash, subject_hash, now, expires_at
        del score_basis_points
        return self.scores


async def test_percentile_is_hidden_below_k_anonymity() -> None:
    service = LeaderboardService(
        repository=MemoryLeaderboardRepository(tuple(range(49))),
        clock=lambda: NOW,
        minimum_cohort_size=50,
    )

    result = await service.percentile(
        cohort=COHORT,
        score_basis_points=2_500,
        subject_id="cihaz-1",
    )

    assert result.status is PercentileStatus.INSUFFICIENT_COHORT
    assert result.percentile_bucket is None
    assert result.cohort_size_bucket == "0-49"


async def test_ties_use_midrank_and_output_is_rounded_to_five() -> None:
    scores = (1_000,) * 10 + (2_500,) * 20 + (9_000,) * 70
    service = LeaderboardService(
        repository=MemoryLeaderboardRepository(scores),
        clock=lambda: NOW,
        minimum_cohort_size=50,
    )

    result = await service.percentile(
        cohort=COHORT,
        score_basis_points=2_500,
        subject_id="cihaz-1",
    )

    assert result.status is PercentileStatus.AVAILABLE
    assert result.percentile_bucket == 20
    assert result.cohort_size_bucket == "100-249"
