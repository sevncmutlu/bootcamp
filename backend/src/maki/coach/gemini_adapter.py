from __future__ import annotations

from typing import cast

import httpx

from maki.coach.ports import CoachProviderError

_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"
_MAXIMUM_OUTPUT_TOKENS = 700
_MAXIMUM_ANSWER_CHARACTERS = 4000
_MAXIMUM_MODEL_NAME_LENGTH = 128
_BAD_REQUEST_START = 400
_SERVER_ERROR_START = 500
_RATE_LIMIT_STATUS = 429
_TIMEOUT_CODE = "PROVIDER_TIMEOUT"
_CONNECTION_CODE = "PROVIDER_CONNECTION_FAILED"
_AUTH_CODE = "PROVIDER_AUTH_FAILED"
_RATE_LIMIT_CODE = "PROVIDER_RATE_LIMITED"
_REJECTED_CODE = "PROVIDER_REJECTED"
_INVALID_RESPONSE_CODE = "PROVIDER_RESPONSE_INVALID"


class GeminiAdapter:
    def __init__(
        self,
        *,
        api_key: str,
        model_name: str,
        client: httpx.AsyncClient | None = None,
    ) -> None:
        cleaned_key = api_key.strip()
        if not cleaned_key or any(character.isspace() for character in cleaned_key):
            msg = "Gemini API anahtarı geçersiz."
            raise ValueError(msg)
        if not model_name.strip() or len(model_name) > _MAXIMUM_MODEL_NAME_LENGTH:
            msg = "Gemini model adı geçersiz."
            raise ValueError(msg)
        self._api_key = cleaned_key
        self._model_name = model_name
        self._owns_client = client is None
        self._client = client or httpx.AsyncClient(
            timeout=httpx.Timeout(20, connect=3, read=15, write=5),
        )

    async def answer(self, *, question: str) -> str:
        try:
            response = await self._client.post(
                f"{_BASE_URL}/{self._model_name}:generateContent",
                headers={"x-goog-api-key": self._api_key},
                json={
                    "systemInstruction": {
                        "parts": [{"text": _system_prompt()}],
                    },
                    "contents": [
                        {"role": "user", "parts": [{"text": question}]},
                    ],
                    "generationConfig": {
                        "maxOutputTokens": _MAXIMUM_OUTPUT_TOKENS,
                    },
                },
            )
        except httpx.TimeoutException as error:
            raise _provider_error(_TIMEOUT_CODE, retryable=True) from error
        except httpx.HTTPError as error:
            raise _provider_error(_CONNECTION_CODE, retryable=True) from error

        if response.status_code in {401, 403}:
            raise _provider_error(_AUTH_CODE, retryable=False)
        if response.status_code == _RATE_LIMIT_STATUS:
            raise _provider_error(_RATE_LIMIT_CODE, retryable=True)
        if response.status_code >= _BAD_REQUEST_START:
            raise _provider_error(
                _REJECTED_CODE,
                retryable=response.status_code >= _SERVER_ERROR_START,
            )
        return _response_text(response)

    async def close(self) -> None:
        if self._owns_client:
            await self._client.aclose()


def _response_text(response: httpx.Response) -> str:
    try:
        payload = cast("dict[str, object]", response.json())
        candidates = cast("list[object]", payload["candidates"])
        candidate = cast("dict[str, object]", candidates[0])
        content = cast("dict[str, object]", candidate["content"])
        parts = cast("list[object]", content["parts"])
        part = cast("dict[str, object]", parts[0])
        text = cast("str", part["text"]).strip()
    except (KeyError, IndexError, TypeError, ValueError) as error:
        raise _provider_error(_INVALID_RESPONSE_CODE, retryable=False) from error
    if not text or len(text) > _MAXIMUM_ANSWER_CHARACTERS:
        raise _provider_error(_INVALID_RESPONSE_CODE, retryable=False)
    return text


def _system_prompt() -> str:
    return (
        "Sen Maki adlı Türkçe kişisel finans eğitim koçusun. Günlük, sade Türkçe kullan. "
        "Kesin yatırım, kredi veya getiri vaadi verme. Kullanıcının sorusunu 2-4 uygulanabilir "
        "adıma çevir. Teknik terim gerekiyorsa aynı cümlede açıkla. Yanıtın sonunda bunun eğitim "
        "amaçlı olduğunu tek kısa cümleyle belirt. Kullanıcının sorusunda silinmiş kişisel bilgi "
        "yer tutucularını tahmin etmeye çalışma."
    )


def _provider_error(code: str, *, retryable: bool) -> CoachProviderError:
    return CoachProviderError(
        code=code,
        message="Gemini koç isteği tamamlanamadı.",
        retryable=retryable,
    )
