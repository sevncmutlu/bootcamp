from pathlib import Path

import pytest

from maki.ocr.paddle_adapter import OcrNotReadyError, PaddleOcrAdapter


def test_missing_local_models_fail_closed(tmp_path: Path) -> None:
    with pytest.raises(OcrNotReadyError, match="yerel"):
        PaddleOcrAdapter.from_local_models(
            detection_model_dir=tmp_path / "missing-det",
            recognition_model_dir=tmp_path / "missing-rec",
        )
