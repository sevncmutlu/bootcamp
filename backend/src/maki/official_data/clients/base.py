from __future__ import annotations

import asyncio
import json
from hashlib import sha256
from typing import TYPE_CHECKING, Protocol
from urllib.parse import urlsplit

import httpx
from pydantic import Field, JsonValue

from maki.common.models import ApiModel

if TYPE_CHECKING:
    from collections.abc import Awaitable, Callable

    from maki.official_data.models import SourceSnapshot

_MAXIMUM_RESPONSE_BYTES = 5 * 1024 * 1024
_MAXIMUM_REDIRECTS = 3
_MAXIMUM_ATTEMPTS = 3
_TOTAL_TIMEOUT_SECONDS = 15
_TOO_MANY_REQUESTS = 429
_SERVER_ERROR_START = 500
_SUCCESS_START = 200
_SUCCESS_END = 300
_MAXIMUM_RETRY_DELAY_SECONDS = 5.0


class ProviderError(Exception):
    """Resmî veri sağlayıcısı hatası."""


class ProviderSchemaError(ProviderError):
    def __init__(self, message: str = "Sağlayıcı yanıt şeması değişti.") -> None:
        super().__init__(message)


class ProviderHttpError(ProviderError):
    def __init__(self, message: str, *, retryable: bool) -> None:
        super().__init__(message)
        self.retryable = retryable


class UnsafeProviderRedirectError(ProviderError):
    def __init__(self) -> None:
        super().__init__("Sağlayıcı yönlendirmesi izinli adresin dışına çıkıyor.")


class ProviderResponseTooLargeError(ProviderError):
    def __init__(self) -> None:
        super().__init__("Sağlayıcı yanıtı 5 MiB sınırını aşıyor.")


class FetchedJson(ApiModel):
    payload: JsonValue
    content_sha256: str = Field(pattern=r"^[0-9a-f]{64}$")
    etag: str | None
    source_url: str = Field(min_length=1, max_length=2048)


class OfficialDataClient(Protocol):
    async def fetch(self) -> SourceSnapshot: ...


def build_official_http_client() -> httpx.AsyncClient:
    timeout = httpx.Timeout(10, connect=2, read=10, write=5, pool=2)
    limits = httpx.Limits(max_connections=20, max_keepalive_connections=10)
    return httpx.AsyncClient(
        timeout=timeout,
        limits=limits,
        follow_redirects=False,
        trust_env=False,
    )


class OfficialHttpClient:
    def __init__(
        self,
        client: httpx.AsyncClient,
        allowed_origin: str,
        *,
        sleeper: Callable[[float], Awaitable[None]] = asyncio.sleep,
        jitter: Callable[[], float] | None = None,
    ) -> None:
        self._client = client
        self._origin = _origin(allowed_origin)
        self._base_url = httpx.URL(allowed_origin)
        self._sleeper = sleeper
        self._jitter = jitter or _zero_jitter

    async def get_json(
        self,
        path: str,
        *,
        headers: dict[str, str] | None = None,
    ) -> FetchedJson:
        url = self._base_url.join(path)
        self._ensure_allowed(url)
        try:
            async with asyncio.timeout(_TOTAL_TIMEOUT_SECONDS):
                return await self._get_with_retries(url, headers or {})
        except (TimeoutError, httpx.TimeoutException) as error:
            message = "Sağlayıcı isteği zaman aşımına uğradı."
            raise ProviderHttpError(
                message,
                retryable=True,
            ) from error
        except httpx.RequestError as error:
            message = "Sağlayıcı bağlantısı kurulamadı."
            raise ProviderHttpError(
                message,
                retryable=True,
            ) from error

    async def _get_with_retries(
        self,
        url: httpx.URL,
        headers: dict[str, str],
    ) -> FetchedJson:
        for attempt in range(_MAXIMUM_ATTEMPTS):
            status, response_headers, body, final_url = await self._send(
                url,
                headers,
            )
            if status == _TOO_MANY_REQUESTS or status >= _SERVER_ERROR_START:
                if attempt == _MAXIMUM_ATTEMPTS - 1:
                    message = "Sağlayıcı geçici olarak kullanılamıyor."
                    raise ProviderHttpError(
                        message,
                        retryable=True,
                    )
                delay = _retry_delay(response_headers, attempt, self._jitter())
                await self._sleeper(delay)
                continue
            if status < _SUCCESS_START or status >= _SUCCESS_END:
                message = "Sağlayıcı isteği reddetti."
                raise ProviderHttpError(
                    message,
                    retryable=False,
                )
            _require_json_media_type(response_headers)
            return _decode_json(body, response_headers, final_url)
        msg = "Sağlayıcı tekrar döngüsü beklenmeyen biçimde sonlandı."
        raise RuntimeError(msg)

    async def _send(
        self,
        initial_url: httpx.URL,
        headers: dict[str, str],
    ) -> tuple[int, httpx.Headers, bytes, httpx.URL]:
        url = initial_url
        for _ in range(_MAXIMUM_REDIRECTS + 1):
            request = self._client.build_request("GET", url, headers=headers)
            response = await self._client.send(
                request,
                stream=True,
                follow_redirects=False,
            )
            try:
                if response.is_redirect:
                    location = response.headers.get("location")
                    if location is None:
                        message = "Sağlayıcı geçersiz yönlendirme döndürdü."
                        raise ProviderHttpError(
                            message,
                            retryable=False,
                        )
                    url = response.url.join(location)
                    self._ensure_allowed(url)
                    continue
                body = await _read_bounded(response)
                return response.status_code, response.headers, body, response.url
            finally:
                await response.aclose()
        message = "Sağlayıcı yönlendirme sınırını aştı."
        raise ProviderHttpError(message, retryable=False)

    def _ensure_allowed(self, url: httpx.URL) -> None:
        if _origin(str(url)) != self._origin:
            raise UnsafeProviderRedirectError


async def _read_bounded(response: httpx.Response) -> bytes:
    content_length = response.headers.get("content-length")
    if content_length is not None:
        try:
            declared_length = int(content_length)
        except ValueError as error:
            message = "Sağlayıcı geçersiz içerik uzunluğu döndürdü."
            raise ProviderHttpError(
                message,
                retryable=False,
            ) from error
        if declared_length > _MAXIMUM_RESPONSE_BYTES:
            raise ProviderResponseTooLargeError

    chunks: list[bytes] = []
    total = 0
    async for chunk in response.aiter_bytes():
        total += len(chunk)
        if total > _MAXIMUM_RESPONSE_BYTES:
            raise ProviderResponseTooLargeError
        chunks.append(chunk)
    return b"".join(chunks)


def _decode_json(
    body: bytes,
    headers: httpx.Headers,
    source_url: httpx.URL,
) -> FetchedJson:
    try:
        payload: JsonValue = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        message = "Sağlayıcı geçerli JSON döndürmedi."
        raise ProviderSchemaError(message) from error
    return FetchedJson(
        payload=payload,
        content_sha256=sha256(body).hexdigest(),
        etag=headers.get("etag"),
        source_url=str(source_url),
    )


def _origin(url: str) -> tuple[str, str, int]:
    parsed = urlsplit(url)
    if parsed.scheme != "https" or not parsed.hostname:
        msg = "Sağlayıcı adresi HTTPS olmalıdır."
        raise ValueError(msg)
    port = parsed.port or 443
    return parsed.scheme, parsed.hostname.lower(), port


def _retry_delay(
    headers: httpx.Headers,
    attempt: int,
    jitter: float,
) -> float:
    retry_after = headers.get("retry-after")
    if retry_after is not None:
        try:
            parsed_delay = float(retry_after)
            return min(
                max(parsed_delay, 0.0),
                _MAXIMUM_RETRY_DELAY_SECONDS,
            )
        except ValueError:
            pass
    safe_jitter = jitter if jitter > 0 else 0.0
    delay = 0.25 * float(2**attempt) + safe_jitter
    return min(_MAXIMUM_RETRY_DELAY_SECONDS, delay)


def _require_json_media_type(headers: httpx.Headers) -> None:
    media_type = headers.get("content-type", "").split(";", maxsplit=1)[0]
    if media_type not in {"application/json", "text/json"}:
        message = "Sağlayıcı JSON içerik türü döndürmedi."
        raise ProviderSchemaError(message)


def _zero_jitter() -> float:
    return 0.0
