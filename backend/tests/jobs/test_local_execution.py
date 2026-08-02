import asyncio
from datetime import UTC, datetime

from maki.coach.adaptive_service import AdaptiveCoachService
from maki.infrastructure.local_execution import LocalExecutionRuntime
from maki.jobs.models import JobKind, JobStatus
from maki.jobs.query import ResultState
from maki.ocr.models import ReceiptResult


class FakeReceiptService:
    async def handle(self, job_id: str, image_bytes: bytes) -> ReceiptResult:
        assert job_id
        assert image_bytes == b"receipt-image"
        return ReceiptResult(
            merchant_name="Maki Market",
            items=(),
            total_minor=12550,
            field_confidences=(),
            requires_review=False,
        )


def _runtime(*, receipt: bool = False) -> LocalExecutionRuntime:
    return LocalExecutionRuntime(
        clock=lambda: datetime.now(UTC),
        coach=AdaptiveCoachService(model_name="gemini-3.5-flash-lite"),
        receipt_service=FakeReceiptService() if receipt else None,
    )


async def _terminal_view(
    runtime: LocalExecutionRuntime,
    *,
    job_id: str,
    owner_id: str,
):
    for _ in range(20):
        view = await runtime.get(job_id=job_id, owner_id=owner_id)
        if view.status.is_terminal:
            return view
        await asyncio.sleep(0)
    raise AssertionError


async def test_local_coach_job_completes_without_database_redis_or_api_key() -> None:
    runtime = _runtime()
    owner = "local-user"

    job = await runtime.accept(
        JobKind.COACH,
        {
            "question": "Nasıl birikim yaparım?",
            "locale": "tr-TR",
            "session_id": "01J00000000000000000000000",
        },
        owner,
        "local-coach-request",
    )
    view = await _terminal_view(runtime, job_id=job.job_id, owner_id=owner)

    assert view.status is JobStatus.SUCCEEDED
    assert view.result_state is ResultState.READY
    assert view.result is not None
    assert view.result.kind == "coach"
    assert view.result.answer.safety.value == "local_guidance"
    await runtime.close()


async def test_local_receipt_bytes_are_consumed_and_result_is_returned() -> None:
    runtime = _runtime(receipt=True)
    owner = "local-user"
    object_ref = await runtime.receipts.put(
        owner_id=owner,
        content=b"receipt-image",
        media_type="image/png",
    )

    job = await runtime.accept(
        JobKind.RECEIPT,
        {"object_ref": object_ref, "media_type": "image/png"},
        owner,
        "local-receipt-request",
    )
    view = await _terminal_view(runtime, job_id=job.job_id, owner_id=owner)

    assert view.status is JobStatus.SUCCEEDED
    assert view.result is not None
    assert view.result.kind == "receipt"
    assert view.result.receipt.merchant_name == "Maki Market"
    assert await runtime.receipts.take(object_ref) is None
    await runtime.close()
