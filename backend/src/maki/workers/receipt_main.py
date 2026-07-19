import asyncio
from datetime import UTC, datetime
from pathlib import Path

from maki.jobs.domain_handlers import ReceiptDomainJobHandler
from maki.jobs.models import JobKind
from maki.ocr.file_guard import FileGuard
from maki.ocr.handler import ReceiptHandler
from maki.ocr.paddle_adapter import PaddleOcrAdapter
from maki.ocr.receipt_parser import ReceiptParser
from maki.workers.worker_bootstrap import (
    ProcessNotConfiguredError,
    WorkerResources,
    run_specialized_worker,
)


class ZeroRetentionReceiptMetadata:
    async def record_completion(
        self,
        job_id: str,
        metadata: dict[str, object],
    ) -> None:
        del job_id, metadata


def main() -> None:
    raise SystemExit(
        asyncio.run(
            run_specialized_worker(
                kind=JobKind.RECEIPT,
                handler_factory=_handler,
            )
        )
    )


def _handler(resources: WorkerResources) -> ReceiptDomainJobHandler:
    detection = resources.settings.ocr.detection_model_dir
    recognition = resources.settings.ocr.recognition_model_dir
    if detection is None or recognition is None:
        raise ProcessNotConfiguredError
    service = ReceiptHandler(
        FileGuard(),
        PaddleOcrAdapter.from_local_models(
            detection_model_dir=Path(detection),
            recognition_model_dir=Path(recognition),
        ),
        ReceiptParser(),
        ZeroRetentionReceiptMetadata(),
        _utc_now,
    )
    return ReceiptDomainJobHandler(
        service,
        resources.receipts,
        resources.results,
    )


def _utc_now() -> datetime:
    return datetime.now(UTC)


if __name__ == "__main__":
    main()
