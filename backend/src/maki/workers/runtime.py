import re
import time
from collections.abc import Callable, Mapping
from datetime import datetime
from typing import Protocol

from maki.jobs.models import JobKind, JobRecord, JobStatus
from maki.jobs.queue import (
    JobClaimOutcome,
    JobQueue,
    QueueDelivery,
    WorkerJobRepository,
)

_FAILURE_CODE_PATTERN = re.compile(r"^[A-Z0-9_]{3,64}$")


class JobHandler(Protocol):
    async def __call__(self, job: JobRecord) -> None: ...


class WorkerTelemetry(Protocol):
    def increment(
        self,
        name: str,
        attributes: Mapping[str, object] | None = None,
        *,
        amount: int = 1,
    ) -> None: ...

    def observe(
        self,
        name: str,
        value: float,
        attributes: Mapping[str, object] | None = None,
    ) -> None: ...


class JobExecutionError(Exception):
    def __init__(self, code: str) -> None:
        if not _FAILURE_CODE_PATTERN.fullmatch(code):
            msg = "İşçi hata kodu geçersiz."
            raise ValueError(msg)
        self.code = code
        super().__init__(code)


class TransientJobError(JobExecutionError):
    pass


class PermanentJobError(JobExecutionError):
    pass


class WorkerRuntime:
    def __init__(
        self,
        *,
        queue: JobQueue,
        repository: WorkerJobRepository,
        handlers: Mapping[JobKind, JobHandler],
        clock: Callable[[], datetime],
        max_attempts: int = 3,
        telemetry: WorkerTelemetry | None = None,
    ) -> None:
        if max_attempts < 1:
            msg = "En fazla deneme sayısı en az bir olmalıdır."
            raise ValueError(msg)
        self._queue = queue
        self._repository = repository
        self._handlers = dict(handlers)
        self._clock = clock
        self._max_attempts = max_attempts
        self._telemetry = telemetry

    async def run_once(self) -> bool:
        delivery = await self._queue.consume()
        if delivery is None:
            return False

        claim = await self._repository.claim_for_work(delivery.message.job_id, self._clock())
        if claim.outcome is JobClaimOutcome.TERMINAL:
            await self._queue.ack(delivery)
            return True
        if claim.outcome is JobClaimOutcome.BUSY:
            await self._queue.release(delivery)
            return True
        if (
            claim.outcome is JobClaimOutcome.MISSING
            or claim.job is None
            or claim.claim_token is None
        ):
            await self._queue.dead_letter(delivery, "IS_BULUNAMADI")
            return True

        await self._execute(delivery, claim.job, claim.claim_token)
        return True

    async def _execute(
        self,
        delivery: QueueDelivery,
        job: JobRecord,
        claim_token: str,
    ) -> None:
        started = time.perf_counter()
        handler = self._handlers.get(job.kind)
        if handler is None:
            failure_code = "ISLEYICI_BULUNAMADI"
            await self._fail_permanently(
                delivery,
                job,
                claim_token,
                failure_code,
            )
            self._record_outcome(job, "failed", started, failure_code)
            return

        try:
            await handler(job)
        except PermanentJobError as error:
            await self._fail_permanently(delivery, job, claim_token, error.code)
            self._record_outcome(job, "failed", started, error.code)
        except TransientJobError as error:
            await self._retry_or_fail(delivery, job, claim_token, error.code)
            outcome = "failed" if job.attempt >= self._max_attempts else "retried"
            self._record_provider_failure(job, error.code)
            self._record_outcome(job, outcome, started, error.code)
        except Exception:  # noqa: BLE001
            # Sağlayıcı hatasının metni kalıcı kayda veya kuyruğa taşınmaz.
            failure_code = "BEKLENMEYEN_ISCI_HATASI"
            await self._retry_or_fail(
                delivery,
                job,
                claim_token,
                failure_code,
            )
            outcome = "failed" if job.attempt >= self._max_attempts else "retried"
            self._record_provider_failure(job, failure_code)
            self._record_outcome(job, outcome, started, failure_code)
        else:
            await self._repository.finish(
                job.job_id,
                JobStatus.SUCCEEDED,
                self._clock(),
                claim_token,
            )
            await self._queue.ack(delivery)
            self._record_outcome(job, "succeeded", started)

    async def _retry_or_fail(
        self,
        delivery: QueueDelivery,
        job: JobRecord,
        claim_token: str,
        failure_code: str,
    ) -> None:
        if job.attempt >= self._max_attempts:
            await self._fail_permanently(delivery, job, claim_token, failure_code)
            return
        await self._repository.finish(
            job.job_id,
            JobStatus.RETRY_WAIT,
            self._clock(),
            claim_token,
            failure_code,
        )
        await self._queue.retry(delivery)

    async def _fail_permanently(
        self,
        delivery: QueueDelivery,
        job: JobRecord,
        claim_token: str,
        failure_code: str,
    ) -> None:
        await self._repository.finish(
            job.job_id,
            JobStatus.FAILED,
            self._clock(),
            claim_token,
            failure_code,
        )
        await self._queue.dead_letter(delivery, failure_code)

    def _record_provider_failure(self, job: JobRecord, failure_code: str) -> None:
        if self._telemetry is None:
            return
        self._telemetry.increment(
            "maki.provider.failures",
            {
                "error.code": failure_code,
                "job.kind": job.kind.value,
            },
        )

    def _record_outcome(
        self,
        job: JobRecord,
        outcome: str,
        started: float,
        failure_code: str | None = None,
    ) -> None:
        if self._telemetry is None:
            return
        attributes = {
            "error.code": failure_code,
            "job.kind": job.kind.value,
            "job.outcome": outcome,
        }
        self._telemetry.increment("maki.jobs.completed", attributes)
        self._telemetry.observe(
            "maki.job.duration_ms",
            (time.perf_counter() - started) * 1_000,
            attributes,
        )
