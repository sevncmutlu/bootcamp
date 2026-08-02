from __future__ import annotations

import asyncio
from datetime import timedelta
from typing import TYPE_CHECKING

from pydantic import JsonValue, ValidationError

from maki.coach.models import CoachQuery
from maki.common.ids import new_ulid
from maki.jobs.domain_handlers import ReceiptDomainJobHandler
from maki.jobs.errors import IdempotencyConflictError
from maki.jobs.models import IdempotencyRecord, JobKind, JobRecord, JobStatus, OutboxRecord
from maki.jobs.query import JobQueryService, JobStatusView
from maki.jobs.results import CoachJobResult, JobResult
from maki.jobs.service import JobService
from maki.workers.runtime import JobExecutionError

if TYPE_CHECKING:
    from collections.abc import Callable
    from datetime import datetime

    from maki.coach.adaptive_service import AdaptiveCoachService
    from maki.jobs.domain_handlers import ReceiptPort


class LocalReceiptStore:
    def __init__(self) -> None:
        self._items: dict[str, bytes] = {}
        self._lock = asyncio.Lock()

    async def put(self, *, owner_id: str, content: bytes, media_type: str) -> str:
        del owner_id, media_type
        object_ref = new_ulid()
        async with self._lock:
            self._items[object_ref] = bytes(content)
        return object_ref

    async def take(self, object_ref: str) -> bytes | None:
        async with self._lock:
            return self._items.pop(object_ref, None)

    async def clear(self) -> None:
        async with self._lock:
            self._items.clear()


class LocalResultStore:
    def __init__(self) -> None:
        self._items: dict[tuple[str, JobKind], JobResult] = {}
        self._lock = asyncio.Lock()

    async def put(self, job_id: str, result: JobResult) -> None:
        async with self._lock:
            self._items[(job_id, JobKind(result.kind))] = result

    async def get(self, job_id: str, kind: JobKind) -> JobResult | None:
        async with self._lock:
            return self._items.get((job_id, kind))

    async def clear(self) -> None:
        async with self._lock:
            self._items.clear()


class LocalExecutionRuntime:
    def __init__(
        self,
        *,
        clock: Callable[[], datetime],
        coach: AdaptiveCoachService,
        receipt_service: ReceiptPort | None,
    ) -> None:
        self.receipts = LocalReceiptStore()
        self.results = LocalResultStore()
        self._clock = clock
        self._coach = coach
        if receipt_service is None:
            self._receipt_handler = None
        else:
            self._receipt_handler = ReceiptDomainJobHandler(
                receipt_service,
                self.receipts,
                self.results,
            )
        self._jobs: dict[str, JobRecord] = {}
        self._idempotency: dict[str, IdempotencyRecord] = {}
        self._tasks: dict[str, asyncio.Task[None]] = {}
        self._lock = asyncio.Lock()
        self._service = JobService(repository=self, clock=clock)
        self._query = JobQueryService(jobs=self, results=self.results)

    @property
    def enabled_job_kinds(self) -> frozenset[JobKind]:
        kinds = {JobKind.COACH}
        if self._receipt_handler is not None:
            kinds.add(JobKind.RECEIPT)
        return frozenset(kinds)

    async def accept(
        self,
        kind: JobKind,
        payload: dict[str, JsonValue],
        owner_id: str,
        idempotency_key: str,
    ) -> JobRecord:
        return await self._accept(
            kind=kind,
            payload=payload,
            owner_id=owner_id,
            idempotency_key=idempotency_key,
            request_api_key=None,
        )

    async def accept_coach(
        self,
        *,
        query: CoachQuery,
        owner_id: str,
        idempotency_key: str,
        request_api_key: str | None,
    ) -> JobRecord:
        return await self._accept(
            kind=JobKind.COACH,
            payload=query.model_dump(mode="json"),
            owner_id=owner_id,
            idempotency_key=idempotency_key,
            request_api_key=request_api_key,
        )

    async def _accept(
        self,
        *,
        kind: JobKind,
        payload: dict[str, JsonValue],
        owner_id: str,
        idempotency_key: str,
        request_api_key: str | None,
    ) -> JobRecord:
        if kind not in self.enabled_job_kinds:
            msg = f"{kind.value} yerel çalışma modunda hazır değil."
            raise RuntimeError(msg)
        job = await self._service.accept(kind, payload, owner_id, idempotency_key)
        async with self._lock:
            current = self._jobs[job.job_id]
            if current.status is not JobStatus.ACCEPTED or job.job_id in self._tasks:
                return current
            queued = current.transition(JobStatus.QUEUED, now=self._clock())
            self._jobs[job.job_id] = queued
            task = asyncio.create_task(
                self._run(queued.job_id, request_api_key=request_api_key),
                name=f"maki-local-{queued.kind.value}-{queued.job_id}",
            )
            self._tasks[job.job_id] = task
            return queued

    async def _run(self, job_id: str, *, request_api_key: str | None) -> None:
        async with self._lock:
            job = self._jobs[job_id].transition(JobStatus.RUNNING, now=self._clock())
            self._jobs[job_id] = job
        try:
            await self._dispatch(job, request_api_key=request_api_key)
        except JobExecutionError as error:
            await self._finish(job_id, JobStatus.FAILED, failure_code=error.code)
        except (ValidationError, ValueError):
            await self._finish(job_id, JobStatus.FAILED, failure_code="IS_GIRDISI_GECERSIZ")
        except Exception:  # noqa: BLE001 - arka plan görevi terminal duruma alınmalıdır.
            await self._finish(job_id, JobStatus.FAILED, failure_code="ISLEM_TAMAMLANAMADI")
        else:
            await self._finish(job_id, JobStatus.SUCCEEDED)

    async def _dispatch(self, job: JobRecord, *, request_api_key: str | None) -> None:
        if job.kind is JobKind.COACH:
            await self._run_coach(job, request_api_key=request_api_key)
            return
        if job.kind is JobKind.RECEIPT and self._receipt_handler is not None:
            await self._receipt_handler(job)
            return
        msg = "Yerel iş türü hazır değil."
        raise RuntimeError(msg)

    async def _run_coach(self, job: JobRecord, *, request_api_key: str | None) -> None:
        query = CoachQuery.model_validate(job.payload)
        answer = await self._coach.answer(query, request_api_key=request_api_key)
        await self.results.put(
            job.job_id,
            CoachJobResult(kind="coach", schema_version=1, answer=answer),
        )

    async def _finish(
        self,
        job_id: str,
        status: JobStatus,
        *,
        failure_code: str | None = None,
    ) -> None:
        async with self._lock:
            self._jobs[job_id] = self._jobs[job_id].transition(
                status,
                now=self._clock(),
                failure_code=failure_code,
            )

    async def create_with_outbox(
        self,
        job: JobRecord,
        outbox: OutboxRecord,
        idempotency: IdempotencyRecord,
    ) -> JobRecord:
        del outbox
        async with self._lock:
            existing = self._idempotency.get(idempotency.key_hash)
            if existing is not None:
                if existing.payload_hash != idempotency.payload_hash:
                    raise IdempotencyConflictError
                return self._jobs[existing.job_id]
            self._jobs[job.job_id] = job
            self._idempotency[idempotency.key_hash] = idempotency
            return job

    async def get_for_owner(self, job_id: str, owner_hash: str) -> JobRecord | None:
        async with self._lock:
            job = self._jobs.get(job_id)
            if job is None or job.owner_hash != owner_hash:
                return None
            return job

    async def get(self, *, job_id: str, owner_id: str) -> JobStatusView:
        return await self._query.get(job_id=job_id, owner_id=owner_id)

    async def close(self) -> None:
        tasks = tuple(self._tasks.values())
        for task in tasks:
            task.cancel()
        if tasks:
            await asyncio.gather(*tasks, return_exceptions=True)
        await self.receipts.clear()
        await self.results.clear()
        async with self._lock:
            self._jobs.clear()
            self._idempotency.clear()


LOCAL_RESULT_TTL = timedelta(minutes=10)
