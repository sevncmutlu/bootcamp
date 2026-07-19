from datetime import UTC, date, datetime
from decimal import Decimal
from enum import StrEnum
from typing import Annotated, Literal, Self

from pydantic import (
    BeforeValidator,
    Field,
    HttpUrl,
    field_validator,
    model_validator,
)

from maki.common.models import ApiModel
from maki.official_data.models import DecimalText


def _citation_tuple(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


CitationNumbers = Annotated[
    tuple[int, ...],
    BeforeValidator(_citation_tuple),
    Field(min_length=1, max_length=5),
]


class CoachSafety(StrEnum):
    ANSWERED = "answered"
    INSUFFICIENT_SOURCES = "insufficient_sources"


class CoachQuery(ApiModel):
    question: str = Field(min_length=1, max_length=2000)
    locale: Literal["tr-TR"] = "tr-TR"
    session_id: str = Field(
        min_length=26,
        max_length=26,
        pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$",
    )


class ProviderAnswer(ApiModel):
    answer: str = Field(min_length=1, max_length=4000)
    cited_source_numbers: CitationNumbers

    @field_validator("cited_source_numbers")
    @classmethod
    def citations_must_be_unique_and_positive(
        cls,
        value: tuple[int, ...],
    ) -> tuple[int, ...]:
        if len(set(value)) != len(value) or any(item <= 0 for item in value):
            msg = "Kaynak numaraları pozitif ve benzersiz olmalıdır."
            raise ValueError(msg)
        return value


class SourceCard(ApiModel):
    snapshot_id: str = Field(
        min_length=26,
        max_length=26,
        pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$",
    )
    snapshot_digest: str = Field(pattern=r"^[0-9a-f]{64}$")
    institution: str = Field(min_length=2, max_length=64)
    series_id: str = Field(pattern=r"^[A-Z0-9_.-]{2,64}$")
    period: date
    value: DecimalText
    unit: str = Field(min_length=1, max_length=32)
    release_date: date
    source_url: HttpUrl
    retrieved_at: datetime

    @field_validator("retrieved_at")
    @classmethod
    def retrieved_at_must_be_utc(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() != UTC.utcoffset(value):
            msg = "Kaynak erişim zamanı UTC olmalıdır."
            raise ValueError(msg)
        return value


class RetrievedContext(ApiModel):
    sources: tuple[SourceCard, ...]
    context_text: str = Field(max_length=6000)
    sources_available: bool

    @model_validator(mode="after")
    def availability_must_match_sources(self) -> Self:
        if self.sources_available != bool(self.sources):
            msg = "Kaynak bulunabilirliği kaynak listesiyle uyuşmuyor."
            raise ValueError(msg)
        if bool(self.context_text) != bool(self.sources):
            msg = "Kaynak metni kaynak listesiyle uyuşmuyor."
            raise ValueError(msg)
        return self


class CoachAnswer(ApiModel):
    answer: str | None = Field(default=None, min_length=1, max_length=4000)
    safety: CoachSafety
    sources: tuple[SourceCard, ...]

    @model_validator(mode="after")
    def safety_must_match_answer(self) -> Self:
        if self.safety is CoachSafety.ANSWERED:
            if self.answer is None or not self.sources:
                msg = "Yanıtlanan koç sonucu cevap ve kaynak taşımalıdır."
                raise ValueError(msg)
        elif self.answer is not None or self.sources:
            msg = "Yetersiz kaynak sonucu cevap veya kaynak taşıyamaz."
            raise ValueError(msg)
        return self


def source_value_text(value: Decimal) -> str:
    return format(value, "f")
