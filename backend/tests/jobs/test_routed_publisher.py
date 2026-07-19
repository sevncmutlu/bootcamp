from maki.infrastructure.redis_queue import RedisJobPublisher
from maki.jobs.models import JobKind
from maki.jobs.queue import JobMessage


class FakeRedis:
    def __init__(self) -> None:
        self.stream: str | None = None
        self.fields: dict[object, object] | None = None

    async def xadd(
        self,
        stream: str,
        fields: dict[object, object],
    ) -> bytes:
        self.stream = stream
        self.fields = fields
        return b"1-0"


async def test_publisher_routes_each_job_kind_to_its_own_stream() -> None:
    redis = FakeRedis()
    publisher = RedisJobPublisher(redis)

    delivery_id = await publisher.publish(
        JobMessage(
            event_id="01K00000000000000000000000",
            job_id="01K00000000000000000000001",
            kind=JobKind.FORECAST,
            version=1,
        )
    )

    assert delivery_id == "1-0"
    assert redis.stream == "maki:jobs:forecast"
