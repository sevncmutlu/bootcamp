from collections.abc import Callable, Mapping
from datetime import UTC, datetime

import jwt
from jwt import InvalidTokenError
from pydantic import Field, ValidationError

from maki.common.ids import new_ulid
from maki.common.models import ApiModel

_MAX_TOKEN_BYTES = 8_192
_ALLOWED_ALGORITHMS = frozenset({"EdDSA", "ES256", "RS256"})
_MIN_TTL_SECONDS = 30
_MAX_TTL_SECONDS = 3_600
_INVALID_CODE = "OTURUM_GECERSIZ"
_INVALID_MESSAGE = "Oturum belirteci doğrulanamadı."
_INVALID_KEY_CODE = "OTURUM_ANAHTARI_GECERSIZ"
_EXPIRED_CODE = "OTURUM_SURESI_DOLDU"
_NOT_ACTIVE_CODE = "OTURUM_HENUZ_GECERLI_DEGIL"


class AuthenticationError(Exception):
    def __init__(self, code: str, message: str) -> None:
        self.code = code
        super().__init__(message)


class TokenClaims(ApiModel):
    sub: str = Field(min_length=1, max_length=256)
    jti: str = Field(min_length=16, max_length=128)
    iss: str = Field(min_length=1, max_length=128)
    aud: str = Field(min_length=1, max_length=128)
    iat: int = Field(ge=0)
    nbf: int = Field(ge=0)
    exp: int = Field(ge=0)


class TokenVerifier:
    def __init__(
        self,
        *,
        public_keys: Mapping[str, bytes | str],
        issuer: str,
        audience: str,
        clock: Callable[[], datetime],
        allowed_algorithms: frozenset[str] = _ALLOWED_ALGORITHMS,
        clock_skew_seconds: int = 0,
    ) -> None:
        if not allowed_algorithms or not allowed_algorithms <= _ALLOWED_ALGORITHMS:
            msg = "JWT algoritma izin listesi geçersiz."
            raise ValueError(msg)
        self._public_keys = dict(public_keys)
        self._issuer = issuer
        self._audience = audience
        self._clock = clock
        self._allowed_algorithms = allowed_algorithms
        self._clock_skew_seconds = clock_skew_seconds

    def verify(self, token: str) -> TokenClaims:
        if len(token.encode()) > _MAX_TOKEN_BYTES:
            raise AuthenticationError(_INVALID_CODE, "Oturum belirteci geçersiz.")

        key_id, algorithm = self._verified_header(token)
        key = self._public_keys.get(key_id)
        if key is None:
            raise AuthenticationError(
                _INVALID_KEY_CODE,
                "Oturum doğrulama anahtarı geçersiz.",
            )

        try:
            decoded = jwt.decode(
                token,
                key=key,
                algorithms=[algorithm],
                issuer=self._issuer,
                audience=self._audience,
                options={
                    "require": ["aud", "exp", "iat", "iss", "jti", "nbf", "sub"],
                    "verify_exp": False,
                    "verify_iat": False,
                    "verify_nbf": False,
                },
            )
            claims = TokenClaims.model_validate(decoded)
        except (InvalidTokenError, ValidationError, UnicodeError) as error:
            raise AuthenticationError(
                _INVALID_CODE,
                _INVALID_MESSAGE,
            ) from error

        self._validate_time(claims)
        return claims

    def _verified_header(self, token: str) -> tuple[str, str]:
        try:
            header = jwt.get_unverified_header(token)
        except InvalidTokenError as error:
            raise AuthenticationError(
                _INVALID_CODE,
                _INVALID_MESSAGE,
            ) from error

        key_id = header.get("kid")
        algorithm = header.get("alg")
        if not isinstance(key_id, str) or not isinstance(algorithm, str):
            raise AuthenticationError(_INVALID_CODE, "Oturum başlığı geçersiz.")
        if algorithm not in self._allowed_algorithms:
            raise AuthenticationError(_INVALID_CODE, "Oturum algoritması geçersiz.")
        return key_id, algorithm

    def _validate_time(self, claims: TokenClaims) -> None:
        now = int(self._clock().astimezone(UTC).timestamp())
        if claims.exp <= now - self._clock_skew_seconds:
            raise AuthenticationError(
                _EXPIRED_CODE,
                "Oturum süresi doldu.",
            )
        if claims.nbf > now + self._clock_skew_seconds:
            raise AuthenticationError(
                _NOT_ACTIVE_CODE,
                "Oturum henüz geçerli değil.",
            )
        if claims.iat > now + self._clock_skew_seconds or claims.exp <= claims.nbf:
            raise AuthenticationError(_INVALID_CODE, "Oturum zaman bilgisi geçersiz.")


class TokenIssuer:
    def __init__(
        self,
        *,
        private_key: bytes | str,
        key_id: str,
        issuer: str,
        audience: str,
        clock: Callable[[], datetime],
        algorithm: str = "EdDSA",
    ) -> None:
        if algorithm not in _ALLOWED_ALGORITHMS:
            msg = "JWT imzalama algoritması geçersiz."
            raise ValueError(msg)
        self._private_key = private_key
        self._key_id = key_id
        self._issuer = issuer
        self._audience = audience
        self._clock = clock
        self._algorithm = algorithm

    def issue(self, *, subject: str, ttl_seconds: int) -> str:
        if not _MIN_TTL_SECONDS <= ttl_seconds <= _MAX_TTL_SECONDS:
            msg = "Oturum süresi 30 ile 3600 saniye arasında olmalıdır."
            raise ValueError(msg)
        now = int(self._clock().astimezone(UTC).timestamp())
        claims = TokenClaims(
            sub=subject,
            jti=new_ulid(),
            iss=self._issuer,
            aud=self._audience,
            iat=now,
            nbf=now,
            exp=now + ttl_seconds,
        )
        return jwt.encode(
            claims.model_dump(mode="json"),
            key=self._private_key,
            algorithm=self._algorithm,
            headers={"kid": self._key_id},
        )
