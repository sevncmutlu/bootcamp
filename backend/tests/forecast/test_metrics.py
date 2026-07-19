import pytest

from maki.forecast.metrics import (
    interval_coverage,
    mae,
    mase,
    wape,
)


def test_known_metric_vectors() -> None:
    actual = (10.0, 20.0, 30.0)
    predicted = (12.0, 18.0, 33.0)

    assert mae(actual, predicted) == pytest.approx(7 / 3)
    assert wape(actual, predicted) == pytest.approx(7 / 60)
    assert mase(
        actual,
        predicted,
        training=(1.0, 2.0, 3.0, 4.0),
        seasonality=1,
    ) == pytest.approx(7 / 3)


def test_zero_denominators_return_none_without_nan() -> None:
    assert wape((0.0, 0.0), (1.0, 1.0)) is None
    assert (
        mase(
            (1.0, 1.0),
            (1.0, 1.0),
            training=(2.0, 2.0, 2.0),
            seasonality=1,
        )
        is None
    )


def test_interval_coverage_is_bounded() -> None:
    assert interval_coverage(
        actual=(1.0, 2.0, 3.0, 4.0),
        lower=(0.0, 2.0, 4.0, 0.0),
        upper=(2.0, 2.0, 5.0, 3.0),
    ) == pytest.approx(0.5)
