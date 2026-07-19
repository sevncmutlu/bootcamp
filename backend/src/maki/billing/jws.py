from __future__ import annotations

import base64
from datetime import UTC, datetime
from itertools import pairwise
from typing import TYPE_CHECKING, Annotated, Literal

from cryptography import x509
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import ec, padding, rsa
from cryptography.hazmat.primitives.asymmetric.utils import encode_dss_signature
from pydantic import BeforeValidator, Field

from maki.billing.google_play import StoreVerificationError
from maki.common.models import ApiModel

if TYPE_CHECKING:
    from collections.abc import Callable

_JWS_PART_COUNT = 3
_ES256_SIGNATURE_BYTES = 64


def _tuple_from_list(value: object) -> object:
    if isinstance(value, list):
        return tuple(value)
    return value


CertificateChain = Annotated[
    tuple[str, ...],
    BeforeValidator(_tuple_from_list),
    Field(min_length=1, max_length=5),
]


class _JwsHeader(ApiModel):
    alg: Literal["ES256"]
    x5c: CertificateChain


class AppleJwsVerifier:
    def __init__(
        self,
        *,
        trusted_root: x509.Certificate,
        clock: Callable[[], datetime],
    ) -> None:
        self._trusted_root = trusted_root
        self._clock = clock

    def verify(self, compact_jws: str) -> bytes:
        parts = compact_jws.split(".")
        if len(parts) != _JWS_PART_COUNT:
            msg = "Apple JWS biçimi geçersiz."
            raise StoreVerificationError(msg)
        encoded_header, encoded_payload, encoded_signature = parts
        try:
            header = _JwsHeader.model_validate_json(_decode(encoded_header))
            certificates = tuple(
                x509.load_der_x509_certificate(base64.b64decode(item, validate=True))
                for item in header.x5c
            )
            signature = _decode(encoded_signature)
        except (TypeError, ValueError):
            msg = "Apple JWS başlığı veya sertifikası geçersiz."
            raise StoreVerificationError(msg) from None
        self._verify_chain(certificates)
        self._verify_signature(
            certificates[0],
            f"{encoded_header}.{encoded_payload}".encode(),
            signature,
        )
        return _decode(encoded_payload)

    def _verify_chain(self, certificates: tuple[x509.Certificate, ...]) -> None:
        now = self._clock().astimezone(UTC)
        chain = certificates
        if chain[-1].fingerprint(hashes.SHA256()) != self._trusted_root.fingerprint(
            hashes.SHA256()
        ):
            chain = (*chain, self._trusted_root)
        if chain[-1].fingerprint(hashes.SHA256()) != self._trusted_root.fingerprint(
            hashes.SHA256()
        ):
            msg = "Apple sertifika kökü güvenilir değil."
            raise StoreVerificationError(msg)
        for certificate in chain:
            if not (certificate.not_valid_before_utc <= now <= certificate.not_valid_after_utc):
                msg = "Apple sertifikasının süresi geçersiz."
                raise StoreVerificationError(msg)
        for certificate, issuer in pairwise(chain):
            if certificate.issuer != issuer.subject:
                msg = "Apple sertifika zinciri eşleşmiyor."
                raise StoreVerificationError(msg)
            _verify_ca_certificate(issuer)
            _verify_certificate_signature(certificate, issuer)

    @staticmethod
    def _verify_signature(
        leaf: x509.Certificate,
        signing_input: bytes,
        signature: bytes,
    ) -> None:
        public_key = leaf.public_key()
        if (
            not isinstance(public_key, ec.EllipticCurvePublicKey)
            or len(signature) != _ES256_SIGNATURE_BYTES
        ):
            msg = "Apple JWS imza anahtarı geçersiz."
            raise StoreVerificationError(msg)
        left = int.from_bytes(signature[:32], "big")
        right = int.from_bytes(signature[32:], "big")
        try:
            public_key.verify(
                encode_dss_signature(left, right),
                signing_input,
                ec.ECDSA(hashes.SHA256()),
            )
        except InvalidSignature:
            msg = "Apple JWS imzası doğrulanamadı."
            raise StoreVerificationError(msg) from None


def _verify_certificate_signature(
    certificate: x509.Certificate,
    issuer: x509.Certificate,
) -> None:
    public_key = issuer.public_key()
    signature_hash = certificate.signature_hash_algorithm
    if signature_hash is None:
        msg = "Apple sertifika özet algoritması bulunamadı."
        raise StoreVerificationError(msg)
    try:
        if isinstance(public_key, ec.EllipticCurvePublicKey):
            public_key.verify(
                certificate.signature,
                certificate.tbs_certificate_bytes,
                ec.ECDSA(signature_hash),
            )
            return
        if isinstance(public_key, rsa.RSAPublicKey):
            public_key.verify(
                certificate.signature,
                certificate.tbs_certificate_bytes,
                padding.PKCS1v15(),
                signature_hash,
            )
            return
    except InvalidSignature:
        pass
    msg = "Apple sertifika imzası doğrulanamadı."
    raise StoreVerificationError(msg)


def _verify_ca_certificate(certificate: x509.Certificate) -> None:
    try:
        constraints = certificate.extensions.get_extension_for_class(x509.BasicConstraints).value
    except x509.ExtensionNotFound:
        msg = "Apple sertifika yetkisi belirtilmemiş."
        raise StoreVerificationError(msg) from None
    if not constraints.ca:
        msg = "Apple sertifika zincirinde yetkisiz imzalayan var."
        raise StoreVerificationError(msg)


def _decode(value: str) -> bytes:
    padding_size = (-len(value)) % 4
    return base64.urlsafe_b64decode(value + "=" * padding_size)
