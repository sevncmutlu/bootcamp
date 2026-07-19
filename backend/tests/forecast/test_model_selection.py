from maki.forecast.models import BacktestMetrics
from maki.forecast.service import (
    BacktestEvaluation,
    ModelSelector,
    SelectionReason,
)


def test_prophet_is_not_selected_when_wape_is_worse() -> None:
    selected = ModelSelector(min_relative_wape_improvement=0.02).select(
        baseline=_result("seasonal_naive", wape=0.10, coverage=None),
        candidate=_result("prophet", wape=0.11, coverage=0.9),
    )

    assert selected.evaluation.model_name == "seasonal_naive"
    assert selected.reason is SelectionReason.BASELINE_WAPE


def test_prophet_requires_two_percent_relative_improvement() -> None:
    selector = ModelSelector(min_relative_wape_improvement=0.02)

    rejected = selector.select(
        baseline=_result("seasonal_naive", wape=0.10, coverage=None),
        candidate=_result("prophet", wape=0.099, coverage=0.9),
    )
    selected = selector.select(
        baseline=_result("seasonal_naive", wape=0.10, coverage=None),
        candidate=_result("prophet", wape=0.097, coverage=0.9),
    )

    assert rejected.evaluation.model_name == "seasonal_naive"
    assert selected.evaluation.model_name == "prophet"
    assert selected.reason is SelectionReason.CANDIDATE_IMPROVEMENT


def test_prophet_with_poor_interval_coverage_is_rejected() -> None:
    selected = ModelSelector(
        min_relative_wape_improvement=0.02,
        minimum_interval_coverage=0.75,
    ).select(
        baseline=_result("seasonal_naive", wape=0.10, coverage=None),
        candidate=_result("prophet", wape=0.05, coverage=0.50),
    )

    assert selected.evaluation.model_name == "seasonal_naive"
    assert selected.reason is SelectionReason.CANDIDATE_COVERAGE


def _result(
    model_name: str,
    *,
    wape: float,
    coverage: float | None,
) -> BacktestEvaluation:
    return BacktestEvaluation(
        model_name=model_name,
        model_version=f"{model_name}-v1",
        metrics=BacktestMetrics(
            mae=0.1,
            wape=wape,
            mase=0.8,
            interval_coverage=coverage,
        ),
        residuals=(0.1, -0.1, 0.05),
    )
