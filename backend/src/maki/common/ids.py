import secrets
import time

_CROCKFORD_ALPHABET = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
_ENTROPY_BYTES = 10
_TIMESTAMP_BITS = 48
_ULID_LENGTH = 26


def new_ulid() -> str:
    timestamp_ms = time.time_ns() // 1_000_000
    if timestamp_ms >= 1 << _TIMESTAMP_BITS:
        msg = "Sistem zamanı ULID aralığının dışında."
        raise OverflowError(msg)

    entropy = int.from_bytes(secrets.token_bytes(_ENTROPY_BYTES))
    value = (timestamp_ms << (_ENTROPY_BYTES * 8)) | entropy
    characters = ["0"] * _ULID_LENGTH
    for index in range(_ULID_LENGTH - 1, -1, -1):
        characters[index] = _CROCKFORD_ALPHABET[value & 31]
        value >>= 5
    return "".join(characters)
