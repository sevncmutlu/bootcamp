from __future__ import annotations

import math
from typing import Annotated, Self

from pydantic import BeforeValidator, Field, field_validator, model_validator

from maki.common.models import ApiModel


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


class RelativePoint(ApiModel):
    day: int = Field(ge=0)
    index: float = Field(gt=0)

    @field_validator("index")
    @classmethod
    def index_must_be_finite(cls, value: float) -> float:
        if not math.isfinite(value):
            msg = "Göreli endeks sonlu olmalıdır."
            raise ValueError(msg)
        return value


RelativePoints = Annotated[
    tuple[RelativePoint, ...],
    BeforeValidator(_tuple_from_list),
]


class RelativeWindow(ApiModel):
    points: RelativePoints = Field(min_length=1, max_length=10_000)

    @model_validator(mode="after")
    def days_must_be_contiguous(self) -> Self:
        first_day = self.points[0].day
        expected = tuple(range(first_day, first_day + len(self.points)))
        actual = tuple(point.day for point in self.points)
        if actual != expected:
            msg = "Göreli seri günleri ardışık olmalıdır."
            raise ValueError(msg)
        return self


class RelativeSeries(ApiModel):
    points: RelativePoints = Field(min_length=56, max_length=10_000)

    @model_validator(mode="after")
    def days_must_start_at_zero_and_be_contiguous(self) -> Self:
        actual = tuple(point.day for point in self.points)
        if actual != tuple(range(len(self.points))):
            msg = "Göreli seri sıfırdan başlayan ardışık günler taşımalıdır."
            raise ValueError(msg)
        return self

    def window(self, start: int, end: int) -> RelativeWindow:
        return RelativeWindow(points=self.points[start:end])


class ForecastPoint(ApiModel):
    horizon_day: int = Field(ge=1)
    prediction: float
    lower: float | None = None
    upper: float | None = None

    @model_validator(mode="after")
    def values_must_be_finite_and_ordered(self) -> Self:
        values = (self.prediction, self.lower, self.upper)
        if any(value is not None and not math.isfinite(value) for value in values):
            msg = "Tahmin değerleri sonlu olmalıdır."
            raise ValueError(msg)
        if (
            self.lower is not None
            and self.upper is not None
            and not self.lower <= self.prediction <= self.upper
        ):
            msg = "Tahmin aralığı nokta tahminini içermelidir."
            raise ValueError(msg)
        return self


ForecastPoints = Annotated[
    tuple[ForecastPoint, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=365),
]


class ForecastCandidate(ApiModel):
    model_name: str = Field(min_length=1, max_length=64)
    model_version: str = Field(min_length=1, max_length=128)
    points: ForecastPoints


class BacktestMetrics(ApiModel):
    mae: float = Field(ge=0)
    wape: float | None = Field(default=None, ge=0)
    mase: float | None = Field(default=None, ge=0)
    interval_coverage: float | None = Field(default=None, ge=0, le=1)

    @model_validator(mode="after")
    def metrics_must_be_finite(self) -> Self:
        values = (self.mae, self.wape, self.mase, self.interval_coverage)
        if any(value is not None and not math.isfinite(value) for value in values):
            msg = "Backtest ölçümleri sonlu olmalıdır."
            raise ValueError(msg)
        return self


class BacktestSplit(ApiModel):
    training: RelativeWindow
    test: RelativeWindow
    origin_day: int = Field(ge=1)
