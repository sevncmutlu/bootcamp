from __future__ import annotations

from typing import TYPE_CHECKING, Annotated

from pydantic import BeforeValidator, Field

from maki.common.models import ApiModel
from maki.forecast.metrics import interval_coverage, mae, mase, wape
from maki.forecast.models import BacktestMetrics, RelativeSeries
from maki.forecast.validation import rolling_origin_splits

if TYPE_CHECKING:
    from maki.forecast.baselines import Forecaster


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


Residuals = Annotated[
    tuple[float, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=100_000),
]


class BacktestEvaluation(ApiModel):
    model_name: str = Field(min_length=1, max_length=64)
    model_version: str = Field(min_length=1, max_length=128)
    metrics: BacktestMetrics
    residuals: Residuals


def evaluate_forecaster(
    *,
    series: RelativeSeries,
    forecaster: Forecaster,
    initial_training_days: int = 42,
    horizon: int = 7,
    step: int = 7,
) -> BacktestEvaluation:
    splits = rolling_origin_splits(
        series,
        initial_training_days=initial_training_days,
        horizon=horizon,
        step=step,
    )
    if not splits:
        msg = "Backtest için yeterli kesim üretilemedi."
        raise ValueError(msg)

    actual: list[float] = []
    predicted: list[float] = []
    lower: list[float] = []
    upper: list[float] = []
    model_identity: tuple[str, str] | None = None
    has_intervals: bool | None = None

    for split in splits:
        candidate = forecaster.forecast(split.training, len(split.test.points))
        model_identity = _consistent_identity(model_identity, candidate)
        current_has_intervals = _append_split_values(
            candidate=candidate,
            actual_values=[point.index for point in split.test.points],
            actual=actual,
            predicted=predicted,
            lower=lower,
            upper=upper,
        )
        if has_intervals is not None and has_intervals != current_has_intervals:
            msg = "Backtest tahmin aralıkları kesimler arasında tutarsız."
            raise ValueError(msg)
        has_intervals = current_has_intervals

    if model_identity is None:
        msg = "Backtest model kimliği üretilemedi."
        raise RuntimeError(msg)
    training_values = [point.index for point in splits[0].training.points]
    coverage = interval_coverage(actual=actual, lower=lower, upper=upper) if has_intervals else None
    return BacktestEvaluation(
        model_name=model_identity[0],
        model_version=model_identity[1],
        metrics=BacktestMetrics(
            mae=mae(actual, predicted),
            wape=wape(actual, predicted),
            mase=mase(
                actual,
                predicted,
                training=training_values,
                seasonality=7,
            ),
            interval_coverage=coverage,
        ),
        residuals=tuple(
            actual_value - predicted_value
            for actual_value, predicted_value in zip(
                actual,
                predicted,
                strict=True,
            )
        ),
    )


def _consistent_identity(
    current: tuple[str, str] | None,
    candidate: object,
) -> tuple[str, str]:
    name = getattr(candidate, "model_name", None)
    version = getattr(candidate, "model_version", None)
    if not isinstance(name, str) or not isinstance(version, str):
        msg = "Backtest modeli geçerli bir kimlik üretmedi."
        raise TypeError(msg)
    identity = (name, version)
    if current is not None and current != identity:
        msg = "Backtest model kimliği kesimler arasında değişti."
        raise ValueError(msg)
    return identity


def _append_split_values(
    *,
    candidate: object,
    actual_values: list[float],
    actual: list[float],
    predicted: list[float],
    lower: list[float],
    upper: list[float],
) -> bool:
    points = getattr(candidate, "points", ())
    if len(points) != len(actual_values):
        msg = "Backtest modeli beklenen tahmin sayısını üretmedi."
        raise ValueError(msg)
    interval_flags = [point.lower is not None and point.upper is not None for point in points]
    if any(interval_flags) and not all(interval_flags):
        msg = "Backtest tahmin aralığı eksik üretildi."
        raise ValueError(msg)
    actual.extend(actual_values)
    predicted.extend(point.prediction for point in points)
    if all(interval_flags):
        lower.extend(point.lower for point in points if point.lower is not None)
        upper.extend(point.upper for point in points if point.upper is not None)
    return all(interval_flags)
