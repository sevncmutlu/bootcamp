import asyncio
import shutil
from collections.abc import AsyncIterator

import pytest
from redis.asyncio import Redis
from testcontainers.core.container import DockerContainer
from testcontainers.core.wait_strategies import LogMessageWaitStrategy

from maki.infrastructure.redis_rate_limit import RedisRateLimiter
from maki.security.rate_limit import RateLimitPolicy

pytestmark = pytest.mark.integration


@pytest.fixture
async def redis_client() -> AsyncIterator[Redis]:
    if shutil.which("docker") is None:
        pytest.skip("Docker bulunamadı; hız sınırı entegrasyon testi çalıştırılamadı.")

    container = (
        DockerContainer("redis:8-alpine")
        .with_exposed_ports(6379)
        .waiting_for(LogMessageWaitStrategy("Ready to accept connections"))
    )
    await asyncio.to_thread(container.start)
    host = container.get_container_host_ip()
    port = container.get_exposed_port(6379)
    client = Redis.from_url(f"redis://{host}:{port}/0", decode_responses=True)
    try:
        yield client
    finally:
        await client.aclose()
        await asyncio.to_thread(container.stop)


async def test_concurrent_requests_cannot_exceed_limit(redis_client: Redis) -> None:
    limiter = RedisRateLimiter(redis_client, fail_open=False)
    policy = RateLimitPolicy(limit=10, window_seconds=60)

    decisions = await asyncio.gather(
        *(
            limiter.check(
                subject="same-device",
                route="/api/v1/forecasts/jobs",
                request_id=f"request-{index}",
                policy=policy,
                now_ms=1_000,
            )
            for index in range(50)
        )
    )

    assert sum(decision.allowed for decision in decisions) == 10
    assert all(decision.remaining == 0 for decision in decisions if not decision.allowed)
