import math

from maki.forecast.models import (
    ForecastCandidate,
    ForecastPoint,
)


class ConformalCalibrator:
    def __init__(self, *, target_coverage: float = 0.8) -> None:
        if not 0 < target_coverage < 1:
            msg = "Hedef kapsama sıfır ile bir arasında olmalıdır."
            raise ValueError(msg)
        self._target_coverage = target_coverage

    def calibrate(
        self,
        candidate: ForecastCandidate,
        residuals: tuple[float, ...],
    ) -> ForecastCandidate:
        width = self._interval_width(residuals)
        return ForecastCandidate(
            model_name=candidate.model_name,
            model_version=candidate.model_version,
            points=tuple(
                ForecastPoint(
                    horizon_day=point.horizon_day,
                    prediction=point.prediction,
                    lower=point.prediction - width,
                    upper=point.prediction + width,
                )
                for point in candidate.points
            ),
        )

    def _interval_width(self, residuals: tuple[float, ...]) -> float:
        if not residuals or any(not math.isfinite(value) for value in residuals):
            msg = "Kalibrasyon artıkları boş olamaz ve sonlu olmalıdır."
            raise ValueError(msg)
        scores = sorted(abs(value) for value in residuals)
        rank = math.ceil((len(scores) + 1) * self._target_coverage)
        return scores[min(rank, len(scores)) - 1]
