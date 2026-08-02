from __future__ import annotations

import argparse
import json
import os
from datetime import UTC, datetime
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

_DETECTION_MODEL = "PP-OCRv6_medium_det"
_RECOGNITION_MODEL = "PP-OCRv6_medium_rec"
_REQUIRED_FILES = ("inference.json", "inference.pdiparams", "inference.yml")


def main() -> int:
    args = _arguments()
    cache_dir = args.cache_dir.resolve()
    os.environ["PADDLE_PDX_CACHE_HOME"] = str(cache_dir)
    os.environ["PADDLE_PDX_MODEL_SOURCE"] = "bos"
    os.environ["PADDLE_PDX_DISABLE_MODEL_SOURCE_CHECK"] = "True"

    from paddleocr import PaddleOCR

    pipeline = PaddleOCR(
        lang="tr",
        ocr_version="PP-OCRv6",
        use_doc_orientation_classify=False,
        use_doc_unwarping=False,
        use_textline_orientation=False,
        enable_mkldnn=False,
    )
    detection = cache_dir / "official_models" / _DETECTION_MODEL
    recognition = cache_dir / "official_models" / _RECOGNITION_MODEL
    _verify_model(detection)
    _verify_model(recognition)
    texts = _smoke_test(pipeline)
    manifest = {
        "ocr_version": "PP-OCRv6",
        "language": "tr",
        "detection_model": _DETECTION_MODEL,
        "recognition_model": _RECOGNITION_MODEL,
        "installed_at": datetime.now(UTC).isoformat(),
        "smoke_texts": texts,
    }
    cache_dir.mkdir(parents=True, exist_ok=True)
    (cache_dir / "maki-ocr-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print("PaddleOCR hazır: Türkçe fiş duman testi tamamlandı.")
    print(f"Tespit modeli: {detection}")
    print(f"Tanıma modeli: {recognition}")
    return 0


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Maki PaddleOCR modellerini hazırlar.")
    parser.add_argument(
        "--cache-dir",
        type=Path,
        default=Path(__file__).resolve().parents[1] / ".local" / "paddle-cache",
    )
    return parser.parse_args()


def _verify_model(directory: Path) -> None:
    missing = [name for name in _REQUIRED_FILES if not (directory / name).is_file()]
    if missing:
        detail = ", ".join(missing)
        raise RuntimeError(f"Model eksik: {directory} ({detail})")


def _smoke_test(pipeline: object) -> list[str]:
    image = Image.new("RGB", (900, 520), "white")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=34)
    rows = (
        "MAKI MARKET",
        "TARIH 31.07.2026",
        "EKMEK 35,50 TL",
        "SUT 90,00 TL",
        "TOPLAM 125,50 TL",
    )
    for index, text in enumerate(rows):
        draw.text((55, 45 + index * 82), text, fill="black", font=font)
    raw_results = list(pipeline.predict(np.asarray(image)))
    texts: list[str] = []
    for raw in raw_results:
        payload = getattr(raw, "json", raw)
        if isinstance(payload, dict) and "res" in payload:
            payload = payload["res"]
        if isinstance(payload, dict):
            values = payload.get("rec_texts", [])
            if isinstance(values, list):
                texts.extend(str(value) for value in values)
    normalized = " ".join(texts).upper()
    if "TOPLAM" not in normalized or "125" not in normalized:
        raise RuntimeError("PaddleOCR duman testi beklenen toplam satırını okuyamadı.")
    return texts


if __name__ == "__main__":
    raise SystemExit(main())
