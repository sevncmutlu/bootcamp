from typing import Protocol

from maki.jobs.models import IdempotencyRecord, JobRecord, OutboxRecord


class JobRepository(Protocol):
    async def create_with_outbox(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord: ...

    async def get_for_owner(
        self,
        job_id: str,
        owner_hash: str,
    ) -> JobRecord | None: ...
