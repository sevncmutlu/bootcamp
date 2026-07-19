import hashlib
from typing import Protocol

from pydantic import Field

from maki.common.models import ApiModel

_MAXIMUM_SUBJECT_LENGTH = 256


class DeletionCounts(ApiModel):
    jobs: int = Field(default=0, ge=0)
    entitlements: int = Field(default=0, ge=0)
    billing_events_anonymized: int = Field(default=0, ge=0)
    leaderboard_contributions: int = Field(default=0, ge=0)


class DeletionRepository(Protocol):
    async def delete_subject(
        self,
        *,
        subject_hash: str,
    ) -> DeletionCounts: ...


class DeletionService:
    def __init__(self, *, repository: DeletionRepository) -> None:
        self._repository = repository

    async def delete(self, *, subject_id: str) -> DeletionCounts:
        if not 1 <= len(subject_id) <= _MAXIMUM_SUBJECT_LENGTH:
            msg = "Silme özne kimliği geçersiz."
            raise ValueError(msg)
        return await self._repository.delete_subject(
            subject_hash=hashlib.sha256(subject_id.encode()).hexdigest()
        )
