import json
from decimal import Decimal
from pathlib import Path

from maki.ocr.models import OcrDocument
from maki.ocr.receipt_parser import ReceiptParser

_FIXTURE = json.loads(Path("tests/fixtures/ocr/receipt-lines.json").read_text(encoding="utf-8"))


def test_receipt_lines_are_grouped_and_reconciled_to_one_kurus() -> None:
    document = OcrDocument.model_validate(_FIXTURE)

    result = ReceiptParser().parse(document)

    assert result.merchant_name == "MAKI MARKET"
    assert len(result.items) == 2
    assert result.items[0].product_name == "EKMEK"
    assert result.items[0].quantity == Decimal(2)
    assert result.items[0].unit_price_minor == 1500
    assert result.items[1].quantity == Decimal("1.5")
    assert result.subtotal_minor == 6000
    assert result.tax_minor == 600
    assert result.discount_minor == 500
    assert result.total_minor == 6100
    assert result.requires_review is False


def test_mismatched_total_requires_review() -> None:
    payload = json.loads(json.dumps(_FIXTURE))
    payload["lines"][-1]["text"] = "GENEL TOPLAM 70,00"

    result = ReceiptParser().parse(OcrDocument.model_validate(payload))

    assert result.requires_review is True
