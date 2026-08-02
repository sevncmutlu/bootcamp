from __future__ import annotations

import re
from dataclasses import dataclass, field
from decimal import Decimal

from maki.ocr.models import (
    FieldConfidence,
    OcrBox,
    OcrDocument,
    OcrLine,
    ReceiptItem,
    ReceiptResult,
)
from maki.official_data.normalization import normalize_decimal

_MONEY_AMOUNT_PATTERN = (
    r"(?:\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?"
    r"|\d{1,3}(?:,\d{3})+(?:\.\d{1,2})?"
    r"|\d+(?:[.,]\d{1,2})?)"
)
_ITEM_WITH_QUANTITY = re.compile(
    r"^(?P<name>.+?)\s+"
    r"(?P<quantity>\d+(?:[.,]\d+)?)\s*[xX]\s*"
    rf"(?P<unit>{_MONEY_AMOUNT_PATTERN})\s+"
    rf"(?P<total>{_MONEY_AMOUNT_PATTERN})$"
)
_MONEY_AT_END = re.compile(
    rf"(?P<value>{_MONEY_AMOUNT_PATTERN})(?:\s*(?:TL|TRY|₺))?\s*$",
    re.IGNORECASE,
)
_VERTICAL_TOLERANCE = 5
_MINIMUM_CONFIDENCE = 0.70
_MONEY_SCALE = Decimal(100)
_RECONCILIATION_TOLERANCE_MINOR = 1
_THOUSANDS_GROUP_DIGITS = 3
_TURKISH_ASCII = str.maketrans(
    {
        "İ": "I",
        "Ş": "S",
        "Ğ": "G",
        "Ü": "U",
        "Ö": "O",
        "Ç": "C",
    }
)


@dataclass(frozen=True, slots=True)
class _GroupedLine:
    text: str
    confidence: float
    box: OcrBox


@dataclass(slots=True)
class _ParseState:
    items: list[ReceiptItem] = field(default_factory=list)
    confidences: list[FieldConfidence] = field(default_factory=list)
    merchant_name: str | None = None
    subtotal: int | None = None
    tax: int = 0
    discount: int = 0
    total: int | None = None
    requires_review: bool = False


class ReceiptParser:
    def parse(self, document: OcrDocument) -> ReceiptResult:
        lines = _group_lines(document.lines)
        state = _ParseState(requires_review=not lines)
        for line in lines:
            _consume_line(state, line)
        _reconcile(state)
        return _result(state)


def _consume_line(state: _ParseState, line: _GroupedLine) -> None:
    summary = _summary(line)
    if summary is not None:
        _apply_summary(state, line, *summary)
        return
    item = _item(line)
    if item is not None:
        state.items.append(item)
        state.confidences.append(
            FieldConfidence(
                field_name=f"item_{len(state.items)}",
                confidence=line.confidence,
            )
        )
        expected = item.quantity * item.unit_price_minor
        if abs(expected - item.line_total_minor) > _RECONCILIATION_TOLERANCE_MINOR:
            state.requires_review = True
        return
    if state.merchant_name is None and not state.items:
        state.merchant_name = line.text
        state.confidences.append(
            FieldConfidence(
                field_name="merchant_name",
                confidence=line.confidence,
            )
        )


def _apply_summary(
    state: _ParseState,
    line: _GroupedLine,
    field_name: str,
    value: int,
) -> None:
    state.confidences.append(
        FieldConfidence(
            field_name=field_name,
            confidence=line.confidence,
        )
    )
    if field_name == "subtotal":
        state.subtotal = value
    elif field_name == "tax":
        state.tax = value
    elif field_name == "discount":
        state.discount = value
    else:
        state.total = value


def _reconcile(state: _ParseState) -> None:
    item_total = sum(item.line_total_minor for item in state.items)
    effective_subtotal = state.subtotal if state.subtotal is not None else item_total
    if (
        state.subtotal is not None
        and abs(state.subtotal - item_total) > _RECONCILIATION_TOLERANCE_MINOR
    ):
        state.requires_review = True
    expected_total = effective_subtotal + state.tax - state.discount
    if state.total is None or abs(state.total - expected_total) > _RECONCILIATION_TOLERANCE_MINOR:
        state.requires_review = True
    if not state.items or any(
        confidence.confidence < _MINIMUM_CONFIDENCE for confidence in state.confidences
    ):
        state.requires_review = True


def _result(state: _ParseState) -> ReceiptResult:
    return ReceiptResult(
        merchant_name=state.merchant_name,
        items=tuple(state.items),
        subtotal_minor=state.subtotal,
        tax_minor=state.tax,
        discount_minor=state.discount,
        total_minor=state.total,
        field_confidences=tuple(state.confidences),
        requires_review=state.requires_review,
    )


def _group_lines(lines: tuple[OcrLine, ...]) -> tuple[_GroupedLine, ...]:
    ordered = sorted(lines, key=lambda line: (_center_y(line.box), line.box.left))
    groups: list[list[OcrLine]] = []
    for line in ordered:
        if not groups or abs(_center_y(groups[-1][0].box) - _center_y(line.box)) > (
            _VERTICAL_TOLERANCE
        ):
            groups.append([line])
        else:
            groups[-1].append(line)
    return tuple(_merge_group(group) for group in groups)


def _merge_group(group: list[OcrLine]) -> _GroupedLine:
    ordered = sorted(group, key=lambda line: line.box.left)
    return _GroupedLine(
        text=" ".join(line.text.strip() for line in ordered),
        confidence=min(line.confidence for line in ordered),
        box=OcrBox(
            left=min(line.box.left for line in ordered),
            top=min(line.box.top for line in ordered),
            right=max(line.box.right for line in ordered),
            bottom=max(line.box.bottom for line in ordered),
        ),
    )


def _center_y(box: OcrBox) -> int:
    return (box.top + box.bottom) // 2


def _summary(line: _GroupedLine) -> tuple[str, int] | None:
    match = _MONEY_AT_END.search(line.text)
    if match is None:
        return None
    normalized = _normalize_label(line.text[: match.start()])
    field_name: str | None = None
    if normalized in {
        "TOPLAM",
        "GENEL TOPLAM",
        "ODENECEK",
        "KART TOPLAMI",
        "TOPKAM",
    }:
        field_name = "total"
    elif normalized == "ARA TOPLAM":
        field_name = "subtotal"
    elif normalized == "KDV":
        field_name = "tax"
    elif normalized in {"INDIRIM", "ISKONTO"}:
        field_name = "discount"
    if field_name is None:
        return None
    return field_name, _money_minor(match.group("value"))


def _item(line: _GroupedLine) -> ReceiptItem | None:
    match = _ITEM_WITH_QUANTITY.fullmatch(line.text)
    if match is None:
        return None
    quantity = normalize_decimal(match.group("quantity"))
    unit_price = _money_minor(match.group("unit"))
    total = _money_minor(match.group("total"))
    return ReceiptItem(
        product_name=match.group("name").strip(),
        quantity=quantity,
        unit_price_minor=unit_price,
        line_total_minor=total,
        confidence=line.confidence,
    )


def _money_minor(value: str) -> int:
    decimal_value = Decimal(_normalize_money(value))
    minor = decimal_value * _MONEY_SCALE
    integral = minor.to_integral_value()
    if minor != integral:
        msg = "Fiş tutarı ikiden fazla ondalık basamak taşıyor."
        raise ValueError(msg)
    return int(integral)


def _normalize_money(value: str) -> str:
    compact = value.strip().replace(" ", "")
    if "," in compact and "." in compact:
        decimal_separator = "," if compact.rfind(",") > compact.rfind(".") else "."
        thousands_separator = "." if decimal_separator == "," else ","
        return compact.replace(thousands_separator, "").replace(decimal_separator, ".")
    for separator in (",", "."):
        if separator not in compact:
            continue
        whole, fraction = compact.rsplit(separator, maxsplit=1)
        if len(fraction) == _THOUSANDS_GROUP_DIGITS and len(whole) <= _THOUSANDS_GROUP_DIGITS:
            return compact.replace(separator, "")
        return f"{whole.replace(separator, '')}.{fraction}"
    return compact


def _normalize_label(value: str) -> str:
    normalized = " ".join(value.upper().translate(_TURKISH_ASCII).split())
    return normalized.replace("0", "O").replace("1", "L")
