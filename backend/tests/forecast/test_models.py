import pytest
from pydantic import ValidationError

from maki.forecast.models import RelativeSeries


def test_relative_series_rejects_amount_date_and_gaps() -> None:
    points = [{"day": day, "index": 1.0} for day in range(56)]
    points[0]["amount"] = 100
    points[1]["date"] = "2026-01-01"
    points[2]["day"] = 3

    with pytest.raises(ValidationError):
        RelativeSeries.model_validate({"points": points})


@pytest.mark.parametrize(
    "bad_index",
    [0.0, -1.0, float("nan"), float("inf")],
)
def test_relative_series_rejects_nonpositive_or_nonfinite_index(
    bad_index: float,
) -> None:
    points = [{"day": day, "index": 1.0} for day in range(56)]
    points[-1]["index"] = bad_index

    with pytest.raises(ValidationError):
        RelativeSeries.model_validate({"points": points})


def test_relative_series_requires_at_least_56_points() -> None:
    with pytest.raises(ValidationError, match="56"):
        RelativeSeries.model_validate({"points": [{"day": day, "index": 1.0} for day in range(55)]})
