from __future__ import annotations

import math
from enum import StrEnum
from typing import TYPE_CHECKING

from pydantic import ValidationError

from maki.common.models import ApiModel
from maki.forecast.backtest import BacktestEvaluation, evaluate_forecaster
from maki.forecast.cache import ForecastCache, ForecastCacheKey
from maki.forecast.calibration import ConformalCalibrator
from maki.forecast.models import ForecastCandidate  # noqa: TC001

if TYPE_CHECKING:
    from maki.forecast.baselines import Forecaster
    from maki.forecast.models import RelativeSeries


class SelectionReason(StrEnum):
    BASELINE_WAPE = "baseline_wape"
    CANDIDATE_COVERAGE = "candidate_coverage"
    CANDIDATE_IMPROVEMENT = "candidate_improvement"
    CANDIDATE_ERROR = "candidate_error"
    BASELINE_ONLY = "baseline_only"


class ModelSelection(ApiModel):
    evaluation: BacktestEvaluation
    reason: SelectionReason


class ModelSelector:
    def __init__(
        self,
        *,
        min_relative_wape_improvement: float = 0.02,
        minimum_interval_coverage: float = 0.75,
    ) -> None:
        if not 0 <= min_relative_wape_improvement < 1:
            msg = "Asgari WAPE iyileşmesi sıfır ile bir arasında olmalıdır."
            raise ValueError(msg)
        if not 0 <= minimum_interval_coverage <= 1:
            msg = "Asgari kapsama sıfır ile bir arasında olmalıdır."
            raise ValueError(msg)
        self._minimum_improvement = min_relative_wape_improvement
        self._minimum_coverage = minimum_interval_coverage

    def select(
        self,
        *,
        baseline: BacktestEvaluation,
        candidate: BacktestEvaluation,
    ) -> ModelSelection:
        if not self._has_enough_coverage(candidate):
            return ModelSelection(
                evaluation=baseline,
                reason=SelectionReason.CANDIDATE_COVERAGE,
            )
        if not self._has_required_improvement(baseline, candidate):
            return ModelSelection(
                evaluation=baseline,
                reason=SelectionReason.BASELINE_WAPE,
            )
        return ModelSelection(
            evaluation=candidate,
            reason=SelectionReason.CANDIDATE_IMPROVEMENT,
        )

    def _has_enough_coverage(self, candidate: BacktestEvaluation) -> bool:
        coverage = candidate.metrics.interval_coverage
        return coverage is not None and coverage >= self._minimum_coverage

    def _has_required_improvement(
        self,
        baseline: BacktestEvaluation,
        candidate: BacktestEvaluation,
    ) -> bool:
        baseline_wape = baseline.metrics.wape
        candidate_wape = candidate.metrics.wape
        if baseline_wape is None or candidate_wape is None or math.isclose(baseline_wape, 0.0):
            return False
        relative_improvement = (baseline_wape - candidate_wape) / baseline_wape
        return relative_improvement >= self._minimum_improvement


class ForecastResult(ApiModel):
    forecast: ForecastCandidate
    evaluation: BacktestEvaluation
    selection_reason: SelectionReason
    cache_hit: bool


class ForecastService:
    def __init__(
        self,
        *,
        baselines: tuple[Forecaster, ...],
        candidates: tuple[Forecaster, ...],
        cache: ForecastCache,
        code_version: str,
        settings_version: str,
    ) -> None:
        if not baselines:
            msg = "En az bir temel tahmin modeli gereklidir."
            raise ValueError(msg)
        self._baselines = baselines
        self._candidates = candidates
        self._cache = cache
        self._code_version = code_version
        self._settings_version = settings_version
        self._selector = ModelSelector()
        self._calibrator = ConformalCalibrator()

    async def forecast(
        self,
        *,
        series: RelativeSeries,
        horizon: int,
    ) -> ForecastResult:
        key = ForecastCacheKey.build(
            series=series,
            horizon=horizon,
            code_version=self._code_version,
            settings_version=self._settings_version,
        )
        cached = await self._load_cached(key.redis_key)
        if cached is not None:
            return cached

        selected, forecaster = self._select_forecaster(series)
        raw_forecast = forecaster.forecast(series, horizon)
        calibrated = self._calibrator.calibrate(
            raw_forecast,
            selected.evaluation.residuals,
        )
        result = ForecastResult(
            forecast=calibrated,
            evaluation=selected.evaluation,
            selection_reason=selected.reason,
            cache_hit=False,
        )
        await self._cache.set(
            key.redis_key,
            result.model_dump_json().encode(),
        )
        return result

    async def _load_cached(self, key: str) -> ForecastResult | None:
        value = await self._cache.get(key)
        if value is None:
            return None
        try:
            cached = ForecastResult.model_validate_json(value)
        except ValidationError:
            return None
        return cached.model_copy(update={"cache_hit": True})

    def _select_forecaster(
        self,
        series: RelativeSeries,
    ) -> tuple[ModelSelection, Forecaster]:
        baseline_pairs = [
            (evaluate_forecaster(series=series, forecaster=model), model)
            for model in self._baselines
        ]
        baseline = min(baseline_pairs, key=lambda pair: _evaluation_score(pair[0]))
        candidates = self._evaluate_candidates(series)
        if not candidates:
            reason = (
                SelectionReason.CANDIDATE_ERROR
                if self._candidates
                else SelectionReason.BASELINE_ONLY
            )
            return (
                ModelSelection(evaluation=baseline[0], reason=reason),
                baseline[1],
            )
        candidate = min(candidates, key=lambda pair: _evaluation_score(pair[0]))
        selection = self._selector.select(
            baseline=baseline[0],
            candidate=candidate[0],
        )
        selected_model = candidate[1] if selection.evaluation == candidate[0] else baseline[1]
        return selection, selected_model

    def _evaluate_candidates(
        self,
        series: RelativeSeries,
    ) -> list[tuple[BacktestEvaluation, Forecaster]]:
        evaluated: list[tuple[BacktestEvaluation, Forecaster]] = []
        for model in self._candidates:
            try:
                evaluation = evaluate_forecaster(
                    series=series,
                    forecaster=model,
                )
            except (ArithmeticError, RuntimeError, ValueError):
                continue
            evaluated.append((evaluation, model))
        return evaluated


def _evaluation_score(evaluation: BacktestEvaluation) -> tuple[bool, float]:
    wape_value = evaluation.metrics.wape
    score = evaluation.metrics.mae if wape_value is None else wape_value
    return (wape_value is None, score)
