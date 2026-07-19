from typing import Protocol

from pydantic import Field

from maki.common.models import ApiModel


class RateLimitPolicy(ApiModel):
    limit: int = Field(ge=1, le=10_000)
    window_seconds: int = Field(ge=1, le=3_600)


class RateLimitDecision(ApiModel):
    allowed: bool
    remaining: int = Field(ge=0)
    retry_after_ms: int = Field(ge=0)
    degraded: bool = False


class RateLimitUnavailableError(Exception):
    def __init__(self) -> None:
        super().__init__("Hız sınırı servisi kullanılamıyor.")


class RateLimiter(Protocol):
    async def check(
        self,
        *,
        subject: str,
        route: str,
        request_id: str,
        policy: RateLimitPolicy,
        now_ms: int,
    ) -> RateLimitDecision: ...
