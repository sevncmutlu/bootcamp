import base64
from io import BytesIO
from pathlib import Path
from typing import ClassVar

import pytest

from maki.ocr.paddle_adapter import OcrNotReadyError, PaddleOcrAdapter

_ONE_PIXEL_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
)


class _FakeResult:
    json: ClassVar[dict[str, object]] = {
        "res": {
            "input_path": None,
            "rec_texts": ["TOPLAM 125,50"],
            "rec_scores": [0.98],
            "rec_boxes": [[1, 2, 100, 30]],
            "rec_polys": [[[1, 2], [100, 2], [100, 30], [1, 30]]],
        }
    }


class _FakePipeline:
    def predict(self, image: object) -> list[object]:
        del image
        return [_FakeResult()]


def test_missing_local_models_fail_closed(tmp_path: Path) -> None:
    with pytest.raises(OcrNotReadyError, match="yerel"):
        PaddleOcrAdapter.from_local_models(
            detection_model_dir=tmp_path / "missing-det",
            recognition_model_dir=tmp_path / "missing-rec",
        )


async def test_provider_metadata_is_ignored_and_ocr_fields_are_validated() -> None:
    document = await PaddleOcrAdapter(_FakePipeline()).extract(BytesIO(_ONE_PIXEL_PNG))

    assert document.lines[0].text == "TOPLAM 125,50"
    assert document.lines[0].confidence == 0.98
