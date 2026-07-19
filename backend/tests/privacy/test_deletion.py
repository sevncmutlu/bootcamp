from maki.privacy.deletion import (
    DeletionCounts,
    DeletionService,
)


class FakeDeletionRepository:
    def __init__(self) -> None:
        self.hashes: list[str] = []

    async def delete_subject(self, *, subject_hash: str) -> DeletionCounts:
        self.hashes.append(subject_hash)
        if len(self.hashes) > 1:
            return DeletionCounts()
        return DeletionCounts(
            jobs=2,
            entitlements=1,
            billing_events_anonymized=3,
            leaderboard_contributions=1,
        )


async def test_deletion_is_subject_bound_counted_and_idempotent() -> None:
    repository = FakeDeletionRepository()
    service = DeletionService(repository=repository)

    first = await service.delete(subject_id="cihaz-1")
    second = await service.delete(subject_id="cihaz-1")

    assert first == DeletionCounts(
        jobs=2,
        entitlements=1,
        billing_events_anonymized=3,
        leaderboard_contributions=1,
    )
    assert second == DeletionCounts()
    assert repository.hashes[0] == repository.hashes[1]
    assert repository.hashes[0] != "cihaz-1"
