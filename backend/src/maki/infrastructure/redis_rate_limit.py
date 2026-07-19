import hashlib
from typing import cast

from pydantic import Field
from redis.asyncio import Redis
from redis.exceptions import RedisError

from maki.common.models import ApiModel
from maki.security.rate_limit import (
    RateLimitDecision,
    RateLimitPolicy,
    RateLimitUnavailableError,
)

_RESULT_FIELD_COUNT = 3
_SLIDING_WINDOW_SCRIPT = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local member = ARGV[4]
redis.call('ZREMRANGEBYSCORE', key, '-inf', now - window)
local count = redis.call('ZCARD', key)
if count >= limit then
    local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
    local retry_after = window
    if oldest[2] then
        retry_after = math.max(0, tonumber(oldest[2]) + window - now)
    end
    return {0, 0, retry_after}
end
redis.call('ZADD', key, now, member)
redis.call('PEXPIRE', key, window + 1000)
count = redis.call('ZCARD', key)
return {1, limit - count, 0}
"""


class _RateLimitInput(ApiModel):
    subject: str = Field(min_length=1, max_length=256)
    route: str = Field(pattern=r"^/api/v1/[a-z0-9_/{}/-]+$", max_length=256)
    request_id: str = Field(min_length=1, max_length=128)
    now_ms: int = Field(ge=0)


class RedisRateLimiter:
    def __init__(self, client: Redis, *, fail_open: bool) -> None:
        self._client = client
        self._fail_open = fail_open

    async def check(
        self,
        *,
        subject: str,
        route: str,
        request_id: str,
        policy: RateLimitPolicy,
        now_ms: int,
    ) -> RateLimitDecision:
        request = _RateLimitInput(
            subject=subject,
            route=route,
            request_id=request_id,
            now_ms=now_ms,
        )
        key = self._key(request.subject, request.route)
        try:
            raw = await self._client.eval(
                _SLIDING_WINDOW_SCRIPT,
                1,
                key,
                request.now_ms,
                policy.window_seconds * 1_000,
                policy.limit,
                request.request_id,
            )
        except RedisError as error:
            if self._fail_open:
                return RateLimitDecision(
                    allowed=True,
                    remaining=policy.limit,
                    retry_after_ms=0,
                    degraded=True,
                )
            raise RateLimitUnavailableError from error

        result = cast("list[int]", raw)
        if len(result) != _RESULT_FIELD_COUNT:
            raise RateLimitUnavailableError
        return RateLimitDecision(
            allowed=bool(result[0]),
            remaining=max(0, result[1]),
            retry_after_ms=max(0, result[2]),
        )

    @staticmethod
    def _key(subject: str, route: str) -> str:
        subject_hash = hashlib.sha256(subject.encode()).hexdigest()
        route_key = route.strip("/").replace("/", ":")
        return f"rate:{{{subject_hash}}}:{route_key}"
