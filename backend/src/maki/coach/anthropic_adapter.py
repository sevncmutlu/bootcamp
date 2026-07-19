from __future__ import annotations

import json
from typing import Protocol, cast

import anthropic
import httpx
from pydantic import ValidationError

from maki.coach.models import ProviderAnswer
from maki.coach.ports import CoachProviderError

_MAXIMUM_OUTPUT_TOKENS = 700
_SERVER_ERROR_START = 500
_MAXIMUM_MODEL_NAME_LENGTH = 128
_TIMEOUT_ERROR = (
    "PROVIDER_TIMEOUT",
    "Koç sağlayıcısı zaman aşımına uğradı.",
)
_RATE_LIMIT_ERROR = (
    "PROVIDER_RATE_LIMITED",
    "Koç sağlayıcısı hız sınırına ulaştı.",
)
_AUTH_ERROR = (
    "PROVIDER_AUTH_FAILED",
    "Koç sağlayıcısı kimliği doğrulanamadı.",
)
_CONNECTION_ERROR = (
    "PROVIDER_CONNECTION_FAILED",
    "Koç sağlayıcısına bağlanılamadı.",
)
_REJECTED_ERROR = (
    "PROVIDER_REJECTED",
    "Koç sağlayıcısı isteği tamamlayamadı.",
)
_INVALID_RESPONSE_ERROR = (
    "PROVIDER_RESPONSE_INVALID",
    "Koç sağlayıcısı yanıtı doğrulanamadı.",
)
_MISSING_TEXT_ERROR = (
    "PROVIDER_RESPONSE_INVALID",
    "Koç sağlayıcısı metin yanıtı döndürmedi.",
)


class _MessagesClient(Protocol):
    async def create(self, **kwargs: object) -> object: ...


class AnthropicAdapter:
    def __init__(
        self,
        messages: _MessagesClient,
        model_name: str,
        *,
        owner: object | None = None,
    ) -> None:
        if not model_name.strip() or len(model_name) > _MAXIMUM_MODEL_NAME_LENGTH:
            msg = "Anthropic model adı boş olamaz."
            raise ValueError(msg)
        self._messages = messages
        self._model_name = model_name
        self._owner = owner

    @classmethod
    def from_credentials(
        cls,
        *,
        api_key: str,
        model_name: str,
    ) -> AnthropicAdapter:
        if not api_key.strip():
            msg = "Anthropic API anahtarı boş olamaz."
            raise ValueError(msg)
        client = anthropic.AsyncAnthropic(
            api_key=api_key,
            timeout=httpx.Timeout(20, connect=2, read=15, write=5),
            max_retries=2,
        )
        return cls(
            messages=cast("_MessagesClient", client.messages),
            model_name=model_name,
            owner=client,
        )

    async def answer(
        self,
        *,
        system_prompt: str,
        user_prompt: str,
    ) -> ProviderAnswer:
        try:
            response = await self._messages.create(
                model=self._model_name,
                max_tokens=_MAXIMUM_OUTPUT_TOKENS,
                temperature=0,
                system=system_prompt,
                messages=[{"role": "user", "content": user_prompt}],
            )
        except anthropic.APITimeoutError as error:
            raise _provider_error(
                *_TIMEOUT_ERROR,
                retryable=True,
            ) from error
        except anthropic.RateLimitError as error:
            raise _provider_error(
                *_RATE_LIMIT_ERROR,
                retryable=True,
            ) from error
        except anthropic.AuthenticationError as error:
            raise _provider_error(
                *_AUTH_ERROR,
                retryable=False,
            ) from error
        except anthropic.APIConnectionError as error:
            raise _provider_error(
                *_CONNECTION_ERROR,
                retryable=True,
            ) from error
        except anthropic.APIStatusError as error:
            retryable = error.status_code >= _SERVER_ERROR_START
            raise _provider_error(
                *_REJECTED_ERROR,
                retryable=retryable,
            ) from error

        text = _response_text(response)
        try:
            decoded = json.loads(text)
            return ProviderAnswer.model_validate(decoded)
        except (json.JSONDecodeError, ValidationError) as error:
            raise _provider_error(
                *_INVALID_RESPONSE_ERROR,
                retryable=False,
            ) from error


def _response_text(response: object) -> str:
    content = cast("object", getattr(response, "content", None))
    if not isinstance(content, list) or len(content) != 1:
        raise _provider_error(
            *_MISSING_TEXT_ERROR,
            retryable=False,
        )
    block = content[0]
    block_type = cast("object", getattr(block, "type", None))
    text = cast("object", getattr(block, "text", None))
    if block_type != "text" or not isinstance(text, str) or not text:
        raise _provider_error(
            *_MISSING_TEXT_ERROR,
            retryable=False,
        )
    return text


def _provider_error(
    code: str,
    message: str,
    *,
    retryable: bool,
) -> CoachProviderError:
    return CoachProviderError(
        code=code,
        message=message,
        retryable=retryable,
    )
