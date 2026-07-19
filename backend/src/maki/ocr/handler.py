from __future__ import annotations

from io import BytesIO
from typing import TYPE_CHECKING, Protocol

if TYPE_CHECKING:
    from collections.abc import Callable
    from datetime import datetime

    from maki.ocr.file_guard import FileGuard
    from maki.ocr.models import OcrDocument, ReceiptResult
    from maki.ocr.receipt_parser import ReceiptParser


class OcrPort(Protocol):
    async def extract(self, stream: BytesIO) -> OcrDocument: ...


class ReceiptRetentionRepository(Protocol):
    async def record_completion(
        self,
        job_id: str,
        metadata: dict[str, object],
    ) -> None: ...


class ReceiptHandler:
    def __init__(
        self,
        file_guard: FileGuard,
        ocr: OcrPort,
        parser: ReceiptParser,
        repository: ReceiptRetentionRepository,
        clock: Callable[[], datetime],
    ) -> None:
        self._file_guard = file_guard
        self._ocr = ocr
        self._parser = parser
        self._repository = repository
        self._clock = clock

    async def handle(self, job_id: str, image_bytes: bytes) -> ReceiptResult:
        sanitized = self._file_guard.sanitize(image_bytes)
        with BytesIO(sanitized.image_bytes) as stream:
            document = await self._ocr.extract(stream)
        result = self._parser.parse(document)
        await self._repository.record_completion(
            job_id,
            {
                "durum": "tamamlandi",
                "kalem_sayisi": len(result.items),
                "inceleme_gerekli": result.requires_review,
                "tamamlanma_zamani": self._clock().isoformat(),
            },
        )
        return result
