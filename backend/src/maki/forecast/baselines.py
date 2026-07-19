from typing import Protocol

from maki.forecast.models import (
    ForecastCandidate,
    ForecastPoint,
    RelativeSeries,
    RelativeWindow,
)

SeriesInput = RelativeSeries | RelativeWindow
_MAXIMUM_HORIZON = 365


class Forecaster(Protocol):
    def forecast(
        self,
        series: SeriesInput,
        horizon: int,
    ) -> ForecastCandidate: ...


class NaiveForecaster:
    model_name = "naive"
    model_version = "naive-v1"

    def forecast(
        self,
        series: SeriesInput,
        horizon: int,
    ) -> ForecastCandidate:
        _validate_horizon(horizon)
        value = series.points[-1].index
        return ForecastCandidate(
            model_name=self.model_name,
            model_version=self.model_version,
            points=tuple(
                ForecastPoint(
                    horizon_day=day,
                    prediction=value,
                )
                for day in range(1, horizon + 1)
            ),
        )


class SeasonalNaiveForecaster:
    model_name = "seasonal_naive"

    def __init__(self, period: int = 7) -> None:
        if period <= 0:
            msg = "Mevsim dönemi sıfırdan büyük olmalıdır."
            raise ValueError(msg)
        self._period = period
        self.model_version = f"seasonal-naive-v1-p{period}"

    def forecast(
        self,
        series: SeriesInput,
        horizon: int,
    ) -> ForecastCandidate:
        _validate_horizon(horizon)
        if len(series.points) < self._period:
            msg = "Mevsimsel temel model için veri yetersiz."
            raise ValueError(msg)
        seasonal_values = [point.index for point in series.points[-self._period :]]
        return ForecastCandidate(
            model_name=self.model_name,
            model_version=self.model_version,
            points=tuple(
                ForecastPoint(
                    horizon_day=day,
                    prediction=seasonal_values[(day - 1) % self._period],
                )
                for day in range(1, horizon + 1)
            ),
        )


def _validate_horizon(horizon: int) -> None:
    if not 1 <= horizon <= _MAXIMUM_HORIZON:
        msg = "Tahmin ufku 1 ile 365 gün arasında olmalıdır."
        raise ValueError(msg)
