from __future__ import annotations

import asyncio
from importlib import import_module
from typing import TYPE_CHECKING, Protocol, cast

from pydantic import Field, ValidationError

from maki.common.models import ApiModel
from maki.ocr.models import OcrBox, OcrDocument, OcrLine
from maki.ocr.preprocess import decode_rgb

if TYPE_CHECKING:
    from collections.abc import Iterable
    from io import BytesIO
    from pathlib import Path

_OCR_VERSION = "PP-OCRv6"
_LANGUAGE = "tr"
_BOX_COORDINATE_COUNT = 4


class OcrNotReadyError(Exception):
    def __init__(self) -> None:
        super().__init__("Türkçe OCR yerel modeli hazır değil.")


class PaddleResponseError(Exception):
    def __init__(self) -> None:
        super().__init__("PaddleOCR yanıt şeması doğrulanamadı.")


class _Pipeline(Protocol):
    def predict(self, image: object) -> Iterable[object]: ...


class _PaddleFactory(Protocol):
    def __call__(self, **kwargs: object) -> object: ...


class _PaddleResult(ApiModel):
    rec_texts: list[str] = Field(max_length=2000)
    rec_scores: list[float] = Field(max_length=2000)
    rec_boxes: list[list[int]] = Field(max_length=2000)


class PaddleOcrAdapter:
    def __init__(self, pipeline: _Pipeline) -> None:
        self._pipeline = pipeline

    @classmethod
    def from_local_models(
        cls,
        *,
        detection_model_dir: Path,
        recognition_model_dir: Path,
    ) -> PaddleOcrAdapter:
        if not detection_model_dir.is_dir() or not recognition_model_dir.is_dir():
            raise OcrNotReadyError
        pipeline = _build_pipeline(
            detection_model_dir=detection_model_dir,
            recognition_model_dir=recognition_model_dir,
        )
        return cls(cast("_Pipeline", pipeline))

    async def extract(self, stream: BytesIO) -> OcrDocument:
        image = decode_rgb(stream.read())
        raw_results = await asyncio.to_thread(lambda: list(self._pipeline.predict(image)))
        lines: list[OcrLine] = []
        for raw in raw_results:
            result = _provider_result(raw)
            if not (len(result.rec_texts) == len(result.rec_scores) == len(result.rec_boxes)):
                raise PaddleResponseError
            lines.extend(
                OcrLine(
                    text=text,
                    confidence=score,
                    box=_box(box),
                )
                for text, score, box in zip(
                    result.rec_texts,
                    result.rec_scores,
                    result.rec_boxes,
                    strict=True,
                )
                if text.strip()
            )
        return OcrDocument(lines=tuple(lines))


def _build_pipeline(
    *,
    detection_model_dir: Path,
    recognition_model_dir: Path,
) -> object:
    module = import_module("paddleocr")
    factory = cast("_PaddleFactory", module.PaddleOCR)
    return factory(
        text_detection_model_dir=str(detection_model_dir),
        text_recognition_model_dir=str(recognition_model_dir),
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
        lang=_LANGUAGE,
        ocr_version=_OCR_VERSION,
    )


def _provider_result(raw: object) -> _PaddleResult:
    payload = cast("object", getattr(raw, "json", raw))
    if isinstance(payload, dict) and "res" in payload:
        payload = payload["res"]
    if isinstance(payload, dict):
        normalized = dict(payload)
        for field in ("rec_texts", "rec_scores", "rec_boxes"):
            value = normalized.get(field)
            to_list = getattr(value, "tolist", None)
            if callable(to_list):
                normalized[field] = cast("object", to_list())
        payload = normalized
    try:
        return _PaddleResult.model_validate(payload)
    except ValidationError as error:
        raise PaddleResponseError from error


def _box(values: list[int]) -> OcrBox:
    if len(values) != _BOX_COORDINATE_COUNT:
        raise PaddleResponseError
    left, top, right, bottom = values
    return OcrBox(left=left, top=top, right=right, bottom=bottom)
