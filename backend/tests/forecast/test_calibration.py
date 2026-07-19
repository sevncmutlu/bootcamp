from maki.forecast.calibration import ConformalCalibrator
from maki.forecast.models import ForecastCandidate, ForecastPoint


def test_conformal_interval_is_deterministic_and_contains_prediction() -> None:
    candidate = ForecastCandidate(
        model_name="seasonal_naive",
        model_version="v1",
        points=(
            ForecastPoint(horizon_day=1, prediction=1.0),
            ForecastPoint(horizon_day=2, prediction=1.2),
        ),
    )
    residuals = (-0.2, -0.1, 0.0, 0.1, 0.3)

    first = ConformalCalibrator(target_coverage=0.8).calibrate(
        candidate,
        residuals,
    )
    second = ConformalCalibrator(target_coverage=0.8).calibrate(
        candidate,
        residuals,
    )

    assert first == second
    assert first.points[0].lower == 0.7
    assert first.points[0].upper == 1.3
    assert all(
        point.lower <= point.prediction <= point.upper
        for point in first.points
        if point.lower is not None and point.upper is not None
    )


def test_native_prophet_interval_is_replaced_by_calibration() -> None:
    candidate = ForecastCandidate(
        model_name="prophet",
        model_version="v1",
        points=(
            ForecastPoint(
                horizon_day=1,
                prediction=1.0,
                lower=0.99,
                upper=1.01,
            ),
        ),
    )

    calibrated = ConformalCalibrator(target_coverage=0.8).calibrate(
        candidate,
        residuals=(-0.5, 0.5, -0.4, 0.4, 0.3),
    )

    assert calibrated.points[0].lower == 0.5
    assert calibrated.points[0].upper == 1.5
