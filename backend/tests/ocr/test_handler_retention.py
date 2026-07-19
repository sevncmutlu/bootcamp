from datetime import UTC, datetime
from io import BytesIO

from PIL import Image

from maki.ocr.file_guard import FileGuard
from maki.ocr.handler import ReceiptHandler
from maki.ocr.models import OcrBox, OcrDocument, OcrLine
from maki.ocr.receipt_parser import ReceiptParser


class SpyOcrAdapter:
    def __init__(self) -> None:
        self.stream: BytesIO | None = None

    async def extract(self, stream: BytesIO) -> OcrDocument:
        self.stream = stream
        return OcrDocument(
            lines=(
                OcrLine(
                    text="MARKET",
                    confidence=0.99,
                    box=OcrBox(left=0, top=0, right=100, bottom=20),
                ),
                OcrLine(
                    text="ÜRÜN 1 x 10,00 10,00",
                    confidence=0.99,
                    box=OcrBox(left=0, top=30, right=100, bottom=50),
                ),
                OcrLine(
                    text="GENEL TOPLAM 10,00",
                    confidence=0.99,
                    box=OcrBox(left=0, top=60, right=100, bottom=80),
                ),
            )
        )


class SpyRetentionRepository:
    def __init__(self) -> None:
        self.metadata: dict[str, object] | None = None

    async def record_completion(
        self,
        job_id: str,
        metadata: dict[str, object],
    ) -> None:
        del job_id
        self.metadata = metadata


async def test_handler_closes_buffer_and_persists_no_receipt_content() -> None:
    adapter = SpyOcrAdapter()
    repository = SpyRetentionRepository()
    handler = ReceiptHandler(
        file_guard=FileGuard(maximum_bytes=100_000, maximum_pixels=10_000),
        ocr=adapter,
        parser=ReceiptParser(),
        repository=repository,
        clock=lambda: datetime(2026, 7, 19, tzinfo=UTC),
    )

    result = await handler.handle("job-1", _image_bytes())

    assert result.total_minor == 1000
    assert adapter.stream is not None
    assert adapter.stream.closed
    assert repository.metadata is not None
    assert set(repository.metadata) == {
        "durum",
        "kalem_sayisi",
        "inceleme_gerekli",
        "tamamlanma_zamani",
    }
    persisted = repr(repository.metadata)
    assert "MARKET" not in persisted
    assert "1000" not in persisted
    assert "ÜRÜN" not in persisted


def _image_bytes() -> bytes:
    image = Image.new("RGB", (20, 20), "white")
    buffer = BytesIO()
    image.save(buffer, format="JPEG")
    return buffer.getvalue()
