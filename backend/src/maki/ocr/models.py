from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BeforeValidator, Field, model_validator

from maki.common.models import ApiModel
from maki.official_data.models import DecimalText


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class OcrBox(ApiModel):
    left: int = Field(ge=0)
    top: int = Field(ge=0)
    right: int = Field(gt=0)
    bottom: int = Field(gt=0)

    @model_validator(mode="after")
    def edges_must_be_ordered(self) -> "OcrBox":
        if self.right <= self.left or self.bottom <= self.top:
            msg = "OCR kutusu pozitif alan taşımalıdır."
            raise ValueError(msg)
        return self


class OcrLine(ApiModel):
    text: str = Field(min_length=1, max_length=500)
    confidence: float = Field(ge=0, le=1)
    box: OcrBox


OcrLines = Annotated[
    tuple[OcrLine, ...],
    BeforeValidator(_tuple_from_list),
    Field(max_length=2000),
]


class OcrDocument(ApiModel):
    lines: OcrLines


class SanitizedImage(ApiModel):
    image_bytes: bytes = Field(min_length=1)
    media_type: Literal["image/jpeg", "image/png"]
    width: int = Field(gt=0)
    height: int = Field(gt=0)


class ReceiptItem(ApiModel):
    product_name: str = Field(min_length=1, max_length=200)
    quantity: DecimalText
    unit_price_minor: int = Field(ge=0)
    line_total_minor: int = Field(ge=0)
    confidence: float = Field(ge=0, le=1)


class FieldConfidence(ApiModel):
    field_name: str = Field(min_length=1, max_length=64)
    confidence: float = Field(ge=0, le=1)


ReceiptItems = Annotated[
    tuple[ReceiptItem, ...],
    BeforeValidator(_tuple_from_list),
    Field(max_length=500),
]
FieldConfidences = Annotated[
    tuple[FieldConfidence, ...],
    BeforeValidator(_tuple_from_list),
    Field(max_length=600),
]


class ReceiptResult(ApiModel):
    merchant_name: str | None = Field(default=None, min_length=1, max_length=200)
    items: ReceiptItems
    subtotal_minor: int | None = Field(default=None, ge=0)
    tax_minor: int = Field(default=0, ge=0)
    discount_minor: int = Field(default=0, ge=0)
    total_minor: int | None = Field(default=None, ge=0)
    field_confidences: FieldConfidences
    requires_review: bool


def quantity_text(value: Decimal) -> str:
    return format(value, "f")
