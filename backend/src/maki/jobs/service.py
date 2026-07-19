import hashlib
from collections.abc import Callable
from datetime import datetime

import orjson
from pydantic import Field, JsonValue

from maki.common.ids import new_ulid
from maki.common.models import ApiModel
from maki.jobs.errors import UnsafeJobPayloadError
from maki.jobs.models import (
    IdempotencyRecord,
    JobKind,
    JobRecord,
    OutboxRecord,
)
from maki.jobs.ports import JobRepository
from maki.privacy.policy import PrivacyPolicy


class _AcceptInput(ApiModel):
    kind: JobKind
    payload: dict[str, JsonValue]
    owner_id: str = Field(min_length=1, max_length=256)
    idempotency_key: str = Field(min_length=8, max_length=128)


class JobService:
    def __init__(
        self,
        *,
        repository: JobRepository,
        clock: Callable[[], datetime],
        privacy_policy: PrivacyPolicy | None = None,
    ) -> None:
        self._repository = repository
        self._clock = clock
        self._privacy_policy = privacy_policy or PrivacyPolicy()

    async def accept(
        self,
        kind: JobKind,
        payload: dict[str, JsonValue],
        owner_id: str,
        idempotency_key: str,
    ) -> JobRecord:
        request = _AcceptInput(
            kind=kind,
            payload=payload,
            owner_id=owner_id,
            idempotency_key=idempotency_key,
        )
        if self._privacy_policy.inspect_json(request.payload):
            raise UnsafeJobPayloadError

        canonical_payload = orjson.dumps(request.payload, option=orjson.OPT_SORT_KEYS)
        payload_hash = hashlib.sha256(canonical_payload).hexdigest()
        owner_hash = hashlib.sha256(request.owner_id.encode()).hexdigest()
        key_hash = self._idempotency_hash(request)
        now = self._clock()
        job = JobRecord.new(
            kind=request.kind,
            owner_hash=owner_hash,
            payload=orjson.loads(canonical_payload),
            payload_hash=payload_hash,
            now=now,
        )
        outbox = OutboxRecord(
            event_id=new_ulid(),
            job_id=job.job_id,
            topic=f"jobs.{request.kind.value}",
            payload={
                "job_id": job.job_id,
                "kind": request.kind.value,
                "version": 1,
            },
            created_at=now,
        )
        idempotency = IdempotencyRecord(
            key_hash=key_hash,
            payload_hash=payload_hash,
            job_id=job.job_id,
            created_at=now,
        )
        return await self._repository.create_with_outbox(job, outbox, idempotency)

    @staticmethod
    def _idempotency_hash(request: _AcceptInput) -> str:
        value = orjson.dumps(
            [request.owner_id, request.kind.value, request.idempotency_key],
            option=orjson.OPT_SORT_KEYS,
        )
        return hashlib.sha256(value).hexdigest()
