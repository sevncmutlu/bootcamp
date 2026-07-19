import hashlib
from collections.abc import Mapping
from typing import Protocol

from pydantic import Field

from maki.common.config import Environment
from maki.common.models import ApiModel
from maki.security.tokens import AuthenticationError

_ATTESTATION_ERROR_CODE = "CIHAZ_DOGRULANAMADI"
_ATTESTATION_ERROR_MESSAGE = "Cihaz doğrulanamadı."


class AttestedDevice(ApiModel):
    provider: str = Field(min_length=1, max_length=32)
    subject_hash: str = Field(pattern=r"^[a-f0-9]{64}$")


class AttestationProvider(Protocol):
    async def verify(self, assertion: str) -> str: ...


class _AttestationInput(ApiModel):
    provider: str = Field(min_length=1, max_length=32)
    assertion: str = Field(min_length=1, max_length=16_384)


class AttestationVerifier:
    def __init__(
        self,
        *,
        environment: Environment,
        providers: Mapping[str, AttestationProvider],
        enable_insecure_dev_auth: bool,
    ) -> None:
        self._environment = environment
        self._providers = dict(providers)
        self._enable_insecure_dev_auth = enable_insecure_dev_auth

    async def verify(self, *, provider: str, assertion: str) -> AttestedDevice:
        request = _AttestationInput(provider=provider, assertion=assertion)
        if self._can_bypass(request.provider):
            return self._device("development", request.assertion)

        adapter = self._providers.get(request.provider)
        if adapter is None:
            raise AuthenticationError(
                _ATTESTATION_ERROR_CODE,
                _ATTESTATION_ERROR_MESSAGE,
            )
        try:
            subject = await adapter.verify(request.assertion)
        except Exception as error:
            raise AuthenticationError(
                _ATTESTATION_ERROR_CODE,
                _ATTESTATION_ERROR_MESSAGE,
            ) from error
        return self._device(request.provider, subject)

    def _can_bypass(self, provider: str) -> bool:
        return (
            self._environment.is_development
            and self._enable_insecure_dev_auth
            and provider == "development"
        )

    @staticmethod
    def _device(provider: str, subject: str) -> AttestedDevice:
        return AttestedDevice(
            provider=provider,
            subject_hash=hashlib.sha256(subject.encode()).hexdigest(),
        )
