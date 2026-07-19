import asyncio
from datetime import UTC, datetime

from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.jobs.errors import IdempotencyConflictError
from maki.jobs.models import (
    IdempotencyRecord,
    JobKind,
    JobRecord,
    OutboxRecord,
)
from maki.jobs.service import JobService
from tests.api.job_fakes import FakeTokenVerifier, authorization_headers

_NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)


class ConcurrentMemoryRepository:
    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self.jobs: dict[str, JobRecord] = {}
        self.keys: dict[str, IdempotencyRecord] = {}
        self.outbox: dict[str, OutboxRecord] = {}

    async def create_with_outbox(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        async with self._lock:
            existing = self.keys.get(idempotency.key_hash)
            if existing is not None:
                if existing.payload_hash != idempotency.payload_hash:
                    raise IdempotencyConflictError
                return self.jobs[existing.job_id]
            self.jobs[job.job_id] = job
            self.keys[idempotency.key_hash] = idempotency
            self.outbox[outbox.event_id] = outbox
            return job


async def test_fifty_concurrent_requests_create_one_job_and_one_event() -> None:
    repository = ConcurrentMemoryRepository()
    service = JobService(repository=repository, clock=lambda: _NOW)
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            token_verifier=FakeTokenVerifier(),
            job_service=service,
            enabled_job_kinds=frozenset({JobKind.COACH}),
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    headers = authorization_headers()
    headers["Idempotency-Key"] = "elli-istek-tek-is"
    payload = {
        "question": "Bütçemi nasıl planlarım?",
        "locale": "tr-TR",
        "session_id": "01K0A1B2C3D4E5F6G7H8J9K0MN",
    }

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        responses = await asyncio.gather(
            *(
                client.post("/api/v1/coach/queries", headers=headers, json=payload)
                for _ in range(50)
            )
        )
        conflict = await client.post(
            "/api/v1/coach/queries",
            headers=headers,
            json={**payload, "question": "Farklı bir soru"},
        )

    assert {response.status_code for response in responses} == {202}
    assert len({response.json()["job_id"] for response in responses}) == 1
    assert len(repository.jobs) == 1
    assert len(repository.outbox) == 1
    assert conflict.status_code == 409
    assert conflict.json()["kod"] == "TEKRARLAMA_ANAHTARI_CAKISTI"
