from __future__ import annotations

import math
from datetime import datetime, timedelta
from importlib import import_module
from typing import TYPE_CHECKING, Any, Protocol, cast

import pandas as pd  # type: ignore[import-untyped]

from maki.forecast.models import ForecastCandidate, ForecastPoint

if TYPE_CHECKING:
    from maki.forecast.baselines import SeriesInput

_SYNTHETIC_START = datetime(2000, 1, 1)  # noqa: DTZ001
_MAXIMUM_HORIZON = 365


class ProphetModel(Protocol):
    def fit(self, frame: pd.DataFrame) -> ProphetModel: ...

    def predict(self, frame: pd.DataFrame) -> pd.DataFrame: ...


class ProphetFactory(Protocol):
    def __call__(self, **kwargs: object) -> ProphetModel: ...


class ProphetAdapter:
    model_name = "prophet"

    def __init__(
        self,
        *,
        factory: ProphetFactory | None = None,
        changepoint_prior_scale: float = 0.05,
        seasonality_prior_scale: float = 1.0,
        interval_width: float = 0.8,
    ) -> None:
        if changepoint_prior_scale <= 0 or seasonality_prior_scale <= 0:
            msg = "Prophet düzenleme katsayıları sıfırdan büyük olmalıdır."
            raise ValueError(msg)
        if not 0 < interval_width < 1:
            msg = "Prophet aralık genişliği sıfır ile bir arasında olmalıdır."
            raise ValueError(msg)
        self._factory = factory or _default_factory
        self._parameters = {
            "changepoint_prior_scale": changepoint_prior_scale,
            "daily_seasonality": False,
            "interval_width": interval_width,
            "seasonality_prior_scale": seasonality_prior_scale,
            "weekly_seasonality": True,
            "yearly_seasonality": False,
        }
        self.model_version = (
            "prophet-v1"
            f"-cp{changepoint_prior_scale:g}"
            f"-sp{seasonality_prior_scale:g}"
            f"-iw{interval_width:g}"
        )

    def forecast(
        self,
        series: SeriesInput,
        horizon: int,
    ) -> ForecastCandidate:
        _validate_horizon(horizon)
        training = _training_frame(series)
        model = self._factory(**self._parameters)
        model.fit(training)
        prediction = model.predict(_future_frame(len(series.points), horizon))
        points = _prediction_points(prediction, horizon)
        return ForecastCandidate(
            model_name=self.model_name,
            model_version=self.model_version,
            points=points,
        )


def _training_frame(series: SeriesInput) -> pd.DataFrame:
    return pd.DataFrame(
        {
            "ds": [_SYNTHETIC_START + timedelta(days=point.day) for point in series.points],
            "y": [point.index for point in series.points],
        },
        columns=["ds", "y"],
    )


def _future_frame(training_length: int, horizon: int) -> pd.DataFrame:
    return pd.DataFrame(
        {
            "ds": [
                _SYNTHETIC_START + timedelta(days=training_length + offset)
                for offset in range(horizon)
            ]
        }
    )


def _prediction_points(
    frame: pd.DataFrame,
    horizon: int,
) -> tuple[ForecastPoint, ...]:
    required_columns = {"yhat", "yhat_lower", "yhat_upper"}
    if len(frame) != horizon or not required_columns.issubset(frame.columns):
        msg = "Prophet beklenen tahmin şemasını üretmedi."
        raise ValueError(msg)
    points: list[ForecastPoint] = []
    for offset, row in enumerate(
        frame.loc[:, ["yhat", "yhat_lower", "yhat_upper"]].itertuples(
            index=False,
            name=None,
        ),
        start=1,
    ):
        prediction, lower, upper = (float(value) for value in row)
        if not all(math.isfinite(value) for value in (prediction, lower, upper)):
            msg = "Prophet sonlu olmayan tahmin üretti."
            raise ValueError(msg)
        points.append(
            ForecastPoint(
                horizon_day=offset,
                prediction=prediction,
                lower=lower,
                upper=upper,
            )
        )
    return tuple(points)


def _default_factory(**kwargs: object) -> ProphetModel:
    prophet_module: Any = import_module("prophet")
    return cast("ProphetModel", prophet_module.Prophet(**kwargs))


def _validate_horizon(horizon: int) -> None:
    if not 1 <= horizon <= _MAXIMUM_HORIZON:
        msg = "Tahmin ufku 1 ile 365 gün arasında olmalıdır."
        raise ValueError(msg)
