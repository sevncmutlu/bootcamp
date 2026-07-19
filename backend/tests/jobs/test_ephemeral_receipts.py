from unittest.mock import AsyncMock

from maki.infrastructure.redis_ephemeral_receipts import (
    RedisEphemeralReceiptStore,
)


async def test_receipt_bytes_are_short_lived_and_read_once() -> None:
    redis = AsyncMock()
    redis.set.return_value = True
    redis.getdel.return_value = b"gorsel"
    store = RedisEphemeralReceiptStore(redis, ttl_seconds=600)

    object_ref = await store.put(
        owner_id="cihaz-1",
        content=b"gorsel",
        media_type="image/png",
    )
    loaded = await store.take(object_ref)

    assert loaded == b"gorsel"
    key = redis.set.await_args.args[0]
    assert "gorsel" not in key
    redis.set.assert_awaited_once_with(
        key,
        b"gorsel",
        ex=600,
        nx=True,
    )
    redis.getdel.assert_awaited_once_with(key)
