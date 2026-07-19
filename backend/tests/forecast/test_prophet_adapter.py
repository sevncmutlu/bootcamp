from datetime import datetime

import pandas as pd

from maki.forecast.models import RelativeSeries
from maki.forecast.prophet_adapter import ProphetAdapter


class FakeProphet:
    def __init__(self, **kwargs: object) -> None:
        self.kwargs = kwargs
        self.training: pd.DataFrame | None = None

    def fit(self, frame: pd.DataFrame) -> "FakeProphet":
        self.training = frame.copy()
        return self

    def predict(self, frame: pd.DataFrame) -> pd.DataFrame:
        assert self.training is not None
        value = float(self.training["y"].iloc[-1])
        return pd.DataFrame(
            {
                "ds": frame["ds"],
                "yhat": [value] * len(frame),
                "yhat_lower": [value - 0.1] * len(frame),
                "yhat_upper": [value + 0.1] * len(frame),
            }
        )


class FakeFactory:
    def __init__(self) -> None:
        self.instance: FakeProphet | None = None

    def __call__(self, **kwargs: object) -> FakeProphet:
        self.instance = FakeProphet(**kwargs)
        return self.instance


def test_prophet_uses_only_synthetic_dates_and_relative_values() -> None:
    factory = FakeFactory()
    series = _series()
    adapter = ProphetAdapter(
        factory=factory,
        changepoint_prior_scale=0.05,
        seasonality_prior_scale=1.0,
    )

    result = adapter.forecast(series, horizon=7)

    assert len(result.points) == 7
    assert factory.instance is not None
    assert factory.instance.training is not None
    training = factory.instance.training
    assert list(training.columns) == ["ds", "y"]
    assert training["ds"].iloc[0] == datetime(2000, 1, 1)  # noqa: DTZ001
    assert training["ds"].iloc[-1] == datetime(2000, 2, 25)  # noqa: DTZ001
    assert list(training["y"]) == [point.index for point in series.points]
    assert factory.instance.kwargs["weekly_seasonality"] is True
    assert factory.instance.kwargs["yearly_seasonality"] is False


def _series() -> RelativeSeries:
    return RelativeSeries.model_validate(
        {"points": [{"day": day, "index": 1.0 + day / 100} for day in range(56)]}
    )
