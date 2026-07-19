from redis.asyncio import Redis
from redis.exceptions import RedisError

from maki.common.ids import new_ulid

_MAXIMUM_IMAGE_BYTES = 8 * 1024 * 1024
_MAXIMUM_TTL_SECONDS = 600
_MAXIMUM_COLLISION_ATTEMPTS = 3
_MAXIMUM_OWNER_ID_LENGTH = 256
_ALLOWED_MEDIA_TYPES = frozenset({"image/jpeg", "image/png"})


class ReceiptStoreUnavailableError(RuntimeError):
    pass


class RedisEphemeralReceiptStore:
    def __init__(self, client: Redis, *, ttl_seconds: int = 600) -> None:
        if not 1 <= ttl_seconds <= _MAXIMUM_TTL_SECONDS:
            msg = "Fiş bellek süresi 1 ile 600 saniye arasında olmalıdır."
            raise ValueError(msg)
        self._client = client
        self._ttl_seconds = ttl_seconds

    async def put(
        self,
        *,
        owner_id: str,
        content: bytes,
        media_type: str,
    ) -> str:
        if not owner_id or len(owner_id) > _MAXIMUM_OWNER_ID_LENGTH:
            msg = "Fiş sahibi kimliği geçersiz."
            raise ValueError(msg)
        if media_type not in _ALLOWED_MEDIA_TYPES:
            msg = "Fiş görsel türü desteklenmiyor."
            raise ValueError(msg)
        if not content or len(content) > _MAXIMUM_IMAGE_BYTES:
            msg = "Fiş görseli boş veya boyut sınırını aşıyor."
            raise ValueError(msg)
        try:
            for _ in range(_MAXIMUM_COLLISION_ATTEMPTS):
                object_ref = new_ulid()
                stored = await self._client.set(
                    _key(object_ref),
                    content,
                    ex=self._ttl_seconds,
                    nx=True,
                )
                if stored:
                    return object_ref
        except RedisError as error:
            raise ReceiptStoreUnavailableError from error
        msg = "Fiş için benzersiz bellek anahtarı üretilemedi."
        raise ReceiptStoreUnavailableError(msg)

    async def take(self, object_ref: str) -> bytes | None:
        try:
            value = await self._client.getdel(_key(object_ref))
        except RedisError as error:
            raise ReceiptStoreUnavailableError from error
        if value is None:
            return None
        return value if isinstance(value, bytes) else str(value).encode()


def _key(object_ref: str) -> str:
    return f"maki:receipt:v1:{object_ref}"
