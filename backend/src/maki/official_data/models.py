from __future__ import annotations

from datetime import UTC, date, datetime
from decimal import Decimal, InvalidOperation
from enum import StrEnum
from typing import Annotated, Literal, Self

from pydantic import (
    BeforeValidator,
    Field,
    HttpUrl,
    field_validator,
    model_validator,
)
from pydantic_core import PydanticCustomError

from maki.common.ids import new_ulid
from maki.common.models import ApiModel


def _decimal_from_text(value: object) -> Decimal:
    if isinstance(value, bool) or not isinstance(value, (str, Decimal)):
        error_code = "decimal_text"
        message = "Seri değeri ondalık metin olmalıdır."
        raise PydanticCustomError(
            error_code,
            message,
        )
    try:
        parsed = Decimal(value)
    except InvalidOperation as error:
        msg = "Seri değeri geçerli bir ondalık sayı olmalıdır."
        raise ValueError(msg) from error
    if not parsed.is_finite():
        msg = "Seri değeri sonlu olmalıdır."
        raise ValueError(msg)
    return parsed


DecimalText = Annotated[
    Decimal,
    BeforeValidator(_decimal_from_text),
    Field(max_digits=38, decimal_places=18),
]


class PublicationState(StrEnum):
    STAGED = "staged"
    PUBLISHED = "published"


class SeriesPoint(ApiModel):
    series_id: str = Field(pattern=r"^[A-Z0-9_.-]{2,64}$")
    period: date
    value: DecimalText
    unit: str = Field(min_length=1, max_length=32)
    frequency: Literal["monthly", "daily"] = "monthly"
    release_date: date
    source_url: HttpUrl
    retrieved_at: datetime

    @field_validator("retrieved_at")
    @classmethod
    def retrieved_at_must_be_utc(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value):
            msg = "Erişim zamanı UTC olmalıdır."
            raise ValueError(msg)
        return value

    @model_validator(mode="after")
    def period_must_match_frequency(self) -> Self:
        if self.frequency == "monthly" and self.period.day != 1:
            msg = "Aylık seri dönemi ayın ilk günü olmalıdır."
            raise ValueError(msg)
        if self.release_date < self.period:
            msg = "Yayın tarihi seri döneminden önce olamaz."
            raise ValueError(msg)
        return self


class SourceSnapshot(ApiModel):
    snapshot_id: str = Field(
        default_factory=new_ulid,
        min_length=26,
        max_length=26,
        pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$",
    )
    source_name: str = Field(pattern=r"^[a-z0-9_-]{2,32}$")
    source_version: str = Field(min_length=1, max_length=128)
    schema_version: int = Field(ge=1, le=100)
    content_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    etag: str | None = Field(default=None, min_length=1, max_length=512)
    points: tuple[SeriesPoint, ...]
    state: PublicationState = PublicationState.STAGED
    published_at: datetime | None = None

    @field_validator("published_at")
    @classmethod
    def published_at_must_be_utc(cls, value: datetime | None) -> datetime | None:
        if value is not None and (
            value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value)
        ):
            msg = "Yayın zamanı UTC olmalıdır."
            raise ValueError(msg)
        return value

    @model_validator(mode="after")
    def state_must_match_publication_time(self) -> Self:
        if self.state is PublicationState.STAGED and self.published_at is not None:
            msg = "Hazırlanan snapshot yayın zamanı taşıyamaz."
            raise ValueError(msg)
        if self.state is PublicationState.PUBLISHED and self.published_at is None:
            msg = "Yayınlanan snapshot yayın zamanı taşımalıdır."
            raise ValueError(msg)
        ordered = tuple(
            sorted(
                self.points,
                key=lambda point: (point.series_id, point.period),
            )
        )
        if ordered != self.points:
            msg = "Snapshot noktaları seri ve dönem sırasıyla gelmelidir."
            raise ValueError(msg)
        return self
