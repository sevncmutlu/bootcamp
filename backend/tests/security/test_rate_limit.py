from unittest.mock import AsyncMock

import pytest
from redis.exceptions import ConnectionError as RedisConnectionError

from maki.infrastructure.redis_rate_limit import RedisRateLimiter
from maki.security.rate_limit import (
    RateLimitPolicy,
    RateLimitUnavailableError,
)


async def test_rate_limit_key_does_not_contain_subject() -> None:
    redis = AsyncMock()
    redis.eval.return_value = [1, 4, 0]
    limiter = RedisRateLimiter(redis, fail_open=False)

    decision = await limiter.check(
        subject="anon-device-42",
        route="/api/v1/coach/queries",
        request_id="request-1",
        policy=RateLimitPolicy(limit=5, window_seconds=60),
        now_ms=1_000,
    )

    key = redis.eval.await_args.args[2]
    assert decision.allowed is True
    assert decision.remaining == 4
    assert "anon-device-42" not in key


async def test_production_rate_limit_fails_closed_when_redis_is_down() -> None:
    redis = AsyncMock()
    redis.eval.side_effect = RedisConnectionError
    limiter = RedisRateLimiter(redis, fail_open=False)

    with pytest.raises(RateLimitUnavailableError, match="Hız sınırı servisi"):
        await limiter.check(
            subject="anon-device",
            route="/api/v1/forecasts/jobs",
            request_id="request-1",
            policy=RateLimitPolicy(limit=5, window_seconds=60),
            now_ms=1_000,
        )


async def test_development_rate_limit_can_fail_open_explicitly() -> None:
    redis = AsyncMock()
    redis.eval.side_effect = RedisConnectionError
    limiter = RedisRateLimiter(redis, fail_open=True)

    decision = await limiter.check(
        subject="anon-device",
        route="/api/v1/test",
        request_id="request-1",
        policy=RateLimitPolicy(limit=5, window_seconds=60),
        now_ms=1_000,
    )

    assert decision.allowed is True
    assert decision.degraded is True
