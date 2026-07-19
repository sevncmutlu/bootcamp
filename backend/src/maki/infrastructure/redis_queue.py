from collections.abc import Mapping
from typing import cast

from redis.asyncio import Redis
from redis.exceptions import ResponseError
from redis.typing import EncodableT

from maki.jobs.models import JobKind
from maki.jobs.queue import JobMessage, QueueDelivery

type StreamFields = dict[EncodableT, EncodableT]
type StreamEntry = tuple[bytes | str, StreamFields]

_AUTOCLAIM_ENTRIES_INDEX = 1


class RedisJobPublisher:
    def __init__(
        self,
        client: Redis,
        *,
        stream_prefix: str = "maki:jobs",
    ) -> None:
        self._client = client
        self._stream_prefix = stream_prefix.rstrip(":")

    async def publish(self, message: JobMessage) -> str:
        stream = f"{self._stream_prefix}:{message.kind.value}"
        result = await self._client.xadd(
            stream,
            RedisJobQueue._fields(message, attempt=0),
        )
        return result.decode() if isinstance(result, bytes) else str(result)


class RedisJobQueue:
    def __init__(
        self,
        client: Redis,
        *,
        stream: str = "maki:jobs",
        group: str = "maki-workers",
        consumer: str,
        visibility_timeout_ms: int = 60_000,
        block_ms: int = 1_000,
    ) -> None:
        self._client = client
        self._stream = stream
        self._failed_stream = f"{stream}:failed"
        self._group = group
        self._consumer = consumer
        self._visibility_timeout_ms = visibility_timeout_ms
        self._block_ms = block_ms
        self._group_ready = False

    async def ensure_group(self) -> None:
        if self._group_ready:
            return
        try:
            await self._client.xgroup_create(
                name=self._stream,
                groupname=self._group,
                id="0-0",
                mkstream=True,
            )
        except ResponseError as error:
            if "BUSYGROUP" not in str(error):
                raise
        self._group_ready = True

    async def publish(self, message: JobMessage) -> str:
        result = await self._client.xadd(self._stream, self._fields(message, attempt=0))
        return self._text(result)

    async def consume(self) -> QueueDelivery | None:
        await self.ensure_group()
        reclaimed = await self._reclaim()
        if reclaimed is not None:
            return reclaimed

        response = await self._client.xreadgroup(
            groupname=self._group,
            consumername=self._consumer,
            streams={self._stream: ">"},
            count=1,
            block=self._block_ms,
        )
        return self._first_delivery(response)

    async def ack(self, delivery: QueueDelivery) -> None:
        await self._client.xack(self._stream, self._group, delivery.delivery_id)

    async def retry(self, delivery: QueueDelivery) -> None:
        async with self._client.pipeline(transaction=True) as pipeline:
            pipeline.xadd(
                self._stream,
                self._fields(delivery.message, attempt=delivery.attempt + 1),
            )
            pipeline.xack(self._stream, self._group, delivery.delivery_id)
            await pipeline.execute()

    async def release(self, _delivery: QueueDelivery) -> None:
        return

    async def dead_letter(self, delivery: QueueDelivery, failure_code: str) -> None:
        fields = self._fields(delivery.message, attempt=delivery.attempt)
        fields["failure_code"] = failure_code
        fields["source_delivery_id"] = delivery.delivery_id
        async with self._client.pipeline(transaction=True) as pipeline:
            pipeline.xadd(self._failed_stream, fields)
            pipeline.xack(self._stream, self._group, delivery.delivery_id)
            await pipeline.execute()

    async def _reclaim(self) -> QueueDelivery | None:
        response = await self._client.xautoclaim(
            name=self._stream,
            groupname=self._group,
            consumername=self._consumer,
            min_idle_time=self._visibility_timeout_ms,
            start_id="0-0",
            count=1,
        )
        if len(response) <= _AUTOCLAIM_ENTRIES_INDEX:
            return None
        entries = cast("list[StreamEntry]", response[_AUTOCLAIM_ENTRIES_INDEX])
        return self._delivery(entries[0]) if entries else None

    @staticmethod
    def _fields(message: JobMessage, *, attempt: int) -> StreamFields:
        return {
            "attempt": str(attempt),
            "event_id": message.event_id,
            "job_id": message.job_id,
            "kind": message.kind.value,
            "traceparent": message.traceparent or "",
            "version": str(message.version),
        }

    @classmethod
    def _first_delivery(cls, response: object) -> QueueDelivery | None:
        streams = cast("list[tuple[str, list[StreamEntry]]]", response)
        if not streams or not streams[0][1]:
            return None
        return cls._delivery(streams[0][1][0])

    @classmethod
    def _delivery(cls, entry: StreamEntry) -> QueueDelivery:
        delivery_id, fields = entry
        return QueueDelivery(
            delivery_id=cls._text(delivery_id),
            message=JobMessage(
                event_id=cls._required(fields, "event_id"),
                job_id=cls._required(fields, "job_id"),
                kind=JobKind(cls._required(fields, "kind")),
                version=int(cls._required(fields, "version")),
                traceparent=cls._optional(fields, "traceparent"),
            ),
            attempt=int(cls._required(fields, "attempt")),
        )

    @classmethod
    def _required(cls, fields: Mapping[EncodableT, EncodableT], key: str) -> str:
        value = fields.get(key)
        if value is None:
            value = fields.get(key.encode())
        if value is None:
            msg = f"Redis iş mesajında {key} alanı yok."
            raise ValueError(msg)
        return cls._text(value)

    @classmethod
    def _optional(cls, fields: Mapping[EncodableT, EncodableT], key: str) -> str | None:
        value = cls._required(fields, key)
        return value or None

    @staticmethod
    def _text(value: object) -> str:
        return value.decode() if isinstance(value, bytes) else str(value)


class RedisProbe:
    name = "redis"

    def __init__(self, client: Redis) -> None:
        self._client = client

    async def is_ready(self) -> bool:
        return bool(await self._client.ping())
