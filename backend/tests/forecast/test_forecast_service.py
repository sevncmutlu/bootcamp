from maki.forecast.baselines import SeasonalNaiveForecaster
from maki.forecast.models import ForecastCandidate, RelativeSeries
from maki.forecast.service import (
    ForecastService,
    SelectionReason,
)


class MemoryCache:
    def __init__(self) -> None:
        self.values: dict[str, bytes] = {}

    async def get(self, key: str) -> bytes | None:
        return self.values.get(key)

    async def set(self, key: str, value: bytes) -> None:
        self.values[key] = value


class BrokenCandidate:
    calls = 0

    def forecast(
        self,
        series: object,
        horizon: int,
    ) -> ForecastCandidate:
        del series, horizon
        self.calls += 1
        msg = "Aday model bozuk."
        raise RuntimeError(msg)


async def test_broken_candidate_falls_back_and_cache_prevents_recalculation() -> None:
    cache = MemoryCache()
    broken = BrokenCandidate()
    service = ForecastService(
        baselines=(SeasonalNaiveForecaster(),),
        candidates=(broken,),
        cache=cache,
        code_version="abc123",
        settings_version="forecast-v2",
    )
    series = _series()

    first = await service.forecast(series=series, horizon=7)
    second = await service.forecast(series=series, horizon=7)

    assert first.forecast.model_name == "seasonal_naive"
    assert first.selection_reason is SelectionReason.CANDIDATE_ERROR
    assert first.cache_hit is False
    assert second.forecast == first.forecast
    assert second.cache_hit is True
    assert broken.calls == 1


def _series() -> RelativeSeries:
    return RelativeSeries.model_validate(
        {"points": [{"day": day, "index": 1.0 + (day % 7) / 100} for day in range(56)]}
    )
