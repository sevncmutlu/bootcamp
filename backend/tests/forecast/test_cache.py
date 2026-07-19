from unittest.mock import AsyncMock

from maki.forecast.cache import ForecastCacheKey, RedisForecastCache
from maki.forecast.models import RelativeSeries


def test_cache_key_contains_hash_not_series_values() -> None:
    series = RelativeSeries.model_validate(
        {"points": [{"day": day, "index": 123.456 + day} for day in range(56)]}
    )

    key = ForecastCacheKey.build(
        series=series,
        horizon=7,
        code_version="abc123",
        settings_version="forecast-v2",
    )

    assert key.redis_key.startswith("maki:forecast:v1:")
    assert "123.456" not in key.redis_key
    assert len(key.series_digest) == 64


async def test_redis_cache_uses_expiry_and_never_puts_payload_in_key() -> None:
    redis = AsyncMock()
    redis.get.return_value = b'{"sonuc":"hazir"}'
    cache = RedisForecastCache(redis, ttl_seconds=300)

    loaded = await cache.get("maki:forecast:v1:ozet")
    await cache.set(
        "maki:forecast:v1:ozet",
        b'{"goreli_deger":123.456}',
    )

    assert loaded == b'{"sonuc":"hazir"}'
    redis.set.assert_awaited_once_with(
        "maki:forecast:v1:ozet",
        b'{"goreli_deger":123.456}',
        ex=300,
    )
