import hashlib
from typing import Protocol

import orjson
from pydantic import Field
from redis.asyncio import Redis
from redis.exceptions import RedisError

from maki.common.models import ApiModel
from maki.forecast.models import RelativeSeries

_MAXIMUM_TTL_SECONDS = 86_400


class ForecastCacheKey(ApiModel):
    series_digest: str = Field(pattern=r"^[0-9a-f]{64}$")
    horizon: int = Field(ge=1, le=365)
    code_version: str = Field(min_length=1, max_length=128)
    settings_version: str = Field(min_length=1, max_length=128)

    @property
    def redis_key(self) -> str:
        version_material = orjson.dumps(
            {
                "code_version": self.code_version,
                "settings_version": self.settings_version,
            },
            option=orjson.OPT_SORT_KEYS,
        )
        version_digest = hashlib.sha256(version_material).hexdigest()[:16]
        return f"maki:forecast:v1:{version_digest}:{self.series_digest}:h{self.horizon}"

    @classmethod
    def build(
        cls,
        *,
        series: RelativeSeries,
        horizon: int,
        code_version: str,
        settings_version: str,
    ) -> "ForecastCacheKey":
        series_material = orjson.dumps(
            [{"day": point.day, "index": point.index} for point in series.points],
            option=orjson.OPT_SORT_KEYS,
        )
        return cls(
            series_digest=hashlib.sha256(series_material).hexdigest(),
            horizon=horizon,
            code_version=code_version,
            settings_version=settings_version,
        )


class ForecastCache(Protocol):
    async def get(self, key: str) -> bytes | None: ...

    async def set(self, key: str, value: bytes) -> None: ...


class RedisForecastCache:
    def __init__(self, client: Redis, *, ttl_seconds: int = 900) -> None:
        if not 1 <= ttl_seconds <= _MAXIMUM_TTL_SECONDS:
            msg = "Tahmin önbellek süresi 1 ile 86400 saniye arasında olmalıdır."
            raise ValueError(msg)
        self._client = client
        self._ttl_seconds = ttl_seconds

    async def get(self, key: str) -> bytes | None:
        try:
            value = await self._client.get(key)
        except RedisError:
            return None
        if value is None:
            return None
        if isinstance(value, bytes):
            return value
        return str(value).encode()

    async def set(self, key: str, value: bytes) -> None:
        try:
            await self._client.set(key, value, ex=self._ttl_seconds)
        except RedisError:
            return
