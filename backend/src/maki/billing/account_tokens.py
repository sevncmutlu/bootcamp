import hashlib
import hmac
from uuid import UUID

_MINIMUM_SECRET_BYTES = 32
_UUID_VERSION_MASK = 0x40
_UUID_VARIANT_MASK = 0x80


class AppleAccountTokenIssuer:
    def __init__(self, *, secret: bytes) -> None:
        if len(secret) < _MINIMUM_SECRET_BYTES:
            msg = "Apple hesap bağı sırrı en az 32 bayt olmalıdır."
            raise ValueError(msg)
        self._secret = secret

    def for_subject(self, subject_id: str) -> str:
        digest = bytearray(
            hmac.new(
                self._secret,
                subject_id.encode(),
                hashlib.sha256,
            ).digest()[:16]
        )
        digest[6] = (digest[6] & 0x0F) | _UUID_VERSION_MASK
        digest[8] = (digest[8] & 0x3F) | _UUID_VARIANT_MASK
        return str(UUID(bytes=bytes(digest)))
