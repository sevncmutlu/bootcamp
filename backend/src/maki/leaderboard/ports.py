from datetime import datetime
from typing import Protocol


class LeaderboardRepository(Protocol):
    async def record_and_list(
        self,
        *,
        cohort_hash: str,
        subject_hash: str,
        score_basis_points: int,
        now: datetime,
        expires_at: datetime,
    ) -> tuple[int, ...]: ...
