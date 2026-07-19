import asyncio
import shutil
from collections.abc import AsyncIterator

import pytest
from redis.asyncio import Redis
from testcontainers.core.container import DockerContainer
from testcontainers.core.wait_strategies import LogMessageWaitStrategy

from maki.infrastructure.redis_queue import RedisJobQueue
from maki.jobs.models import JobKind
from maki.jobs.queue import JobMessage

pytestmark = pytest.mark.integration


@pytest.fixture
async def redis_client() -> AsyncIterator[Redis]:
    if shutil.which("docker") is None:
        pytest.skip("Docker bulunamadı; Redis entegrasyon testi çalıştırılamadı.")

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


async def test_pending_message_is_reclaimed_after_visibility_timeout(
    redis_client: Redis,
) -> None:
    first = RedisJobQueue(
        redis_client,
        stream="maki:test:jobs",
        group="workers",
        consumer="worker-1",
        visibility_timeout_ms=1,
        block_ms=1,
    )
    second = RedisJobQueue(
        redis_client,
        stream="maki:test:jobs",
        group="workers",
        consumer="worker-2",
        visibility_timeout_ms=1,
        block_ms=1,
    )
    await first.ensure_group()
    await first.publish(_message())

    original = await first.consume()
    assert original is not None
    await asyncio.sleep(0.01)
    reclaimed = await second.consume()

    assert reclaimed is not None
    assert reclaimed.delivery_id == original.delivery_id
    await second.ack(reclaimed)
    assert (
        await redis_client.xpending_range(
            "maki:test:jobs",
            "workers",
            min="-",
            max="+",
            count=10,
        )
        == []
    )


async def test_dead_letter_is_written_and_original_is_acknowledged(
    redis_client: Redis,
) -> None:
    queue = RedisJobQueue(
        redis_client,
        stream="maki:test:dead",
        group="workers",
        consumer="worker-1",
        block_ms=1,
    )
    await queue.ensure_group()
    await queue.publish(_message())
    delivery = await queue.consume()
    assert delivery is not None

    await queue.dead_letter(delivery, "KALICI_HATA")

    assert await redis_client.xlen("maki:test:dead:failed") == 1
    assert (
        await redis_client.xpending_range(
            "maki:test:dead",
            "workers",
            min="-",
            max="+",
            count=10,
        )
        == []
    )


def _message() -> JobMessage:
    return JobMessage(
        event_id="01K0A1B2C3D4E5F6G7H8J9K0MN",
        job_id="01K0N1P2Q3R4S5T6V7W8X9Y0ZA",
        kind=JobKind.FORECAST,
        version=1,
        traceparent="00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01",
    )
