from maki.forecast.baselines import (
    NaiveForecaster,
    SeasonalNaiveForecaster,
)
from maki.forecast.models import RelativeSeries
from maki.forecast.validation import rolling_origin_splits


def test_naive_forecaster_repeats_last_value() -> None:
    series = _series()

    result = NaiveForecaster().forecast(series, horizon=3)

    assert result.model_name == "naive"
    assert [point.prediction for point in result.points] == [series.points[-1].index] * 3


def test_seasonal_naive_repeats_last_week() -> None:
    series = _series()

    result = SeasonalNaiveForecaster(period=7).forecast(
        series,
        horizon=10,
    )

    expected = [series.points[-7 + (index % 7)].index for index in range(10)]
    assert [point.prediction for point in result.points] == expected


def test_rolling_origin_splits_never_leak_test_into_training() -> None:
    series = _series(length=70)

    splits = rolling_origin_splits(
        series,
        initial_training_days=42,
        horizon=7,
        step=7,
    )

    assert len(splits) == 4
    for split in splits:
        assert split.training.points[-1].day < split.test.points[0].day
        assert len(split.test.points) == 7


def _series(length: int = 56) -> RelativeSeries:
    return RelativeSeries.model_validate(
        {"points": [{"day": day, "index": 1.0 + day / 100} for day in range(length)]}
    )
