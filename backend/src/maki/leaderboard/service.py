import hashlib
import math
from collections.abc import Callable
from datetime import datetime, timedelta

import orjson

from maki.leaderboard.models import (
    CohortKey,
    CohortPercentile,
    CohortSizeBucket,
    PercentileStatus,
)
from maki.leaderboard.ports import LeaderboardRepository

_CONTRIBUTION_TTL = timedelta(days=7)
_MINIMUM_K_ANONYMITY = 50
_MAXIMUM_K_ANONYMITY = 10_000
_MAXIMUM_SCORE = 10_000
_MAXIMUM_SUBJECT_LENGTH = 256
_MEDIUM_COHORT_BOUNDARY = 100
_LARGE_COHORT_BOUNDARY = 250


class LeaderboardService:
    def __init__(
        self,
        *,
        repository: LeaderboardRepository,
        clock: Callable[[], datetime],
        minimum_cohort_size: int = 50,
    ) -> None:
        if not _MINIMUM_K_ANONYMITY <= minimum_cohort_size <= _MAXIMUM_K_ANONYMITY:
            msg = "Asgari kohort boyutu 50 ile 10000 arasında olmalıdır."
            raise ValueError(msg)
        self._repository = repository
        self._clock = clock
        self._minimum_size = minimum_cohort_size

    async def percentile(
        self,
        *,
        cohort: CohortKey,
        score_basis_points: int,
        subject_id: str,
    ) -> CohortPercentile:
        if not 0 <= score_basis_points <= _MAXIMUM_SCORE:
            msg = "Liderlik skoru 0 ile 10000 arasında olmalıdır."
            raise ValueError(msg)
        if not subject_id or len(subject_id) > _MAXIMUM_SUBJECT_LENGTH:
            msg = "Liderlik oturum kimliği geçersiz."
            raise ValueError(msg)
        now = self._clock()
        scores = await self._repository.record_and_list(
            cohort_hash=_cohort_hash(cohort),
            subject_hash=hashlib.sha256(subject_id.encode()).hexdigest(),
            score_basis_points=score_basis_points,
            now=now,
            expires_at=now + _CONTRIBUTION_TTL,
        )
        size_bucket = _size_bucket(len(scores))
        if len(scores) < self._minimum_size:
            return CohortPercentile(
                status=PercentileStatus.INSUFFICIENT_COHORT,
                cohort_size_bucket=size_bucket,
            )
        less = sum(score < score_basis_points for score in scores)
        equal = sum(score == score_basis_points for score in scores)
        percentile = 100 * (less + equal / 2) / len(scores)
        rounded = min(100, 5 * math.floor(percentile / 5 + 0.5))
        return CohortPercentile(
            status=PercentileStatus.AVAILABLE,
            percentile_bucket=rounded,
            cohort_size_bucket=size_bucket,
        )


def _cohort_hash(cohort: CohortKey) -> str:
    value = orjson.dumps(
        cohort.model_dump(mode="json"),
        option=orjson.OPT_SORT_KEYS,
    )
    return hashlib.sha256(value).hexdigest()


def _size_bucket(size: int) -> CohortSizeBucket:
    if size < _MINIMUM_K_ANONYMITY:
        return "0-49"
    if size < _MEDIUM_COHORT_BOUNDARY:
        return "50-99"
    if size < _LARGE_COHORT_BOUNDARY:
        return "100-249"
    return "250+"
