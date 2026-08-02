from __future__ import annotations

import argparse
import io
import sys
import time
from datetime import UTC, datetime
from pathlib import Path

import httpx
from PIL import Image, ImageDraw, ImageFont

from maki.security.tokens import TokenIssuer


class CapabilitiesNotReadyError(RuntimeError):
    def __init__(self, capabilities: object) -> None:
        super().__init__(f"Yerel özellikler hazır değil: {capabilities}")


class LocalJobFailedError(RuntimeError):
    def __init__(self, failure_code: object) -> None:
        super().__init__(f"Yerel işlem başarısız: {failure_code}")


class LocalJobTimeoutError(TimeoutError):
    def __init__(self) -> None:
        super().__init__("Yerel işlem zamanında tamamlanmadı.")


def main() -> int:
    args = _arguments()
    root = Path(__file__).resolve().parents[1]
    private_key = (root / ".local" / "dev-auth" / "maki-dev-private.pem").read_bytes()
    token = TokenIssuer(
        private_key=private_key,
        key_id="development",
        issuer="maki",
        audience="maki-mobile",
        clock=lambda: datetime.now(UTC),
    ).issue(subject="maki-local-check", ttl_seconds=300)
    headers = {"Authorization": f"Bearer {token}"}

    with httpx.Client(base_url=args.base_url, timeout=120) as client:
        capabilities = client.get("/health/capabilities").raise_for_status().json()
        if not capabilities.get("fis_tarama") or not capabilities.get("maki_koc"):
            raise CapabilitiesNotReadyError(capabilities)
        coach = _coach_check(client, headers)
        receipt = _receipt_check(client, headers)

    sys.stdout.write(f"Maki Koç hazır: {coach['answer']['safety']}\n")
    sys.stdout.write(
        "PaddleOCR hazır: "
        f"{receipt.get('merchant_name') or 'mağaza okundu'} / "
        f"{receipt.get('total_minor')} kuruş\n"
    )
    return 0


def _coach_check(client: httpx.Client, headers: dict[str, str]) -> dict[str, object]:
    response = client.post(
        "/api/v1/coach/queries",
        headers={**headers, "Idempotency-Key": f"check-coach-{time.time_ns()}"},
        json={
            "question": "Borç planımı nasıl düzenleyebilirim?",
            "locale": "tr-TR",
            "session_id": "01J00000000000000000000000",
        },
    )
    response.raise_for_status()
    return _poll(client, headers, response.json()["status_url"])["result"]


def _receipt_check(client: httpx.Client, headers: dict[str, str]) -> dict[str, object]:
    response = client.post(
        "/api/v1/receipts/jobs",
        headers={**headers, "Idempotency-Key": f"check-receipt-{time.time_ns()}"},
        files={"file": ("maki-test-fis.png", _receipt_image(), "image/png")},
    )
    response.raise_for_status()
    result = _poll(client, headers, response.json()["status_url"])["result"]
    return result["receipt"]


def _poll(
    client: httpx.Client,
    headers: dict[str, str],
    status_url: str,
) -> dict[str, object]:
    for _ in range(120):
        payload = client.get(status_url, headers=headers).raise_for_status().json()
        if payload["status"] == "succeeded":
            return payload
        if payload["status"] == "failed":
            raise LocalJobFailedError(payload["failure_code"])
        time.sleep(0.2)
    raise LocalJobTimeoutError


def _receipt_image() -> bytes:
    image = Image.new("RGB", (900, 520), "white")
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=34)
    for index, text in enumerate(
        (
            "MAKI MARKET",
            "TARIH 31.07.2026",
            "EKMEK 35,50 TL",
            "SUT 90,00 TL",
            "TOPLAM 125,50 TL",
        )
    ):
        draw.text((55, 45 + index * 82), text, fill="black", font=font)
    buffer = io.BytesIO()
    image.save(buffer, format="PNG")
    return buffer.getvalue()


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Yerel Maki servislerini uçtan uca dener.")
    parser.add_argument("--base-url", default="http://127.0.0.1:8000")
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
