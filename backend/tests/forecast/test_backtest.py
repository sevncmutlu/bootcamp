from maki.forecast.backtest import evaluate_forecaster
from maki.forecast.baselines import SeasonalNaiveForecaster
from maki.forecast.models import RelativeSeries


def test_backtest_collects_every_test_point_without_leakage() -> None:
    series = _series()

    evaluation = evaluate_forecaster(
        series=series,
        forecaster=SeasonalNaiveForecaster(),
        initial_training_days=42,
        horizon=7,
        step=7,
    )

    assert evaluation.model_name == "seasonal_naive"
    assert len(evaluation.residuals) == 14
    assert evaluation.metrics.wape is not None
    assert evaluation.metrics.interval_coverage is None


def _series() -> RelativeSeries:
    return RelativeSeries.model_validate(
        {"points": [{"day": day, "index": 1.0 + (day % 7) / 100} for day in range(56)]}
    )
