import base64
import json
from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import cast

import pytest
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
from cryptography.hazmat.primitives.asymmetric.utils import (
    decode_dss_signature,
)
from cryptography.x509.oid import NameOID

from maki.billing.app_store import AppStoreVerifier
from maki.billing.google_play import StoreVerificationError
from maki.billing.models import StoreEvent

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)
FIXTURE = Path(__file__).parents[1] / "fixtures" / "billing" / "apple-jws.json"


async def test_apple_jws_chain_signature_and_payload_are_verified() -> None:
    root_key, root = _certificate_authority()
    leaf_key, leaf = _leaf(root_key, root)
    verifier = AppStoreVerifier(
        trusted_root=root,
        bundle_id="com.team120.maki.makiApp",
        allowed_products=frozenset({"maki_debt_pro"}),
        environment="Production",
        clock=lambda: NOW,
    )
    signed = _jws(leaf_key, leaf, _payload())

    transaction = verifier.verify(
        signed_transaction=signed,
        expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
        subject_hash="a" * 64,
    )

    assert transaction.verified is True
    assert transaction.event is StoreEvent.RENEWED
    assert transaction.product_id == "maki_debt_pro"


async def test_tampered_apple_payload_is_rejected() -> None:
    root_key, root = _certificate_authority()
    leaf_key, leaf = _leaf(root_key, root)
    verifier = AppStoreVerifier(
        trusted_root=root,
        bundle_id="com.team120.maki.makiApp",
        allowed_products=frozenset({"maki_debt_pro"}),
        environment="Production",
        clock=lambda: NOW,
    )
    signed = _jws(leaf_key, leaf, _payload())
    header, _, signature = signed.split(".")
    tampered_payload = _encode({**_payload(), "bundleId": "com.attacker"})

    with pytest.raises(StoreVerificationError, match="imza"):
        verifier.verify(
            signed_transaction=f"{header}.{tampered_payload}.{signature}",
            expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
            subject_hash="a" * 64,
        )


def test_untrusted_apple_certificate_root_is_rejected() -> None:
    trusted_key, trusted_root = _certificate_authority()
    del trusted_key
    untrusted_key, untrusted_root = _certificate_authority()
    leaf_key, leaf = _leaf(untrusted_key, untrusted_root)
    verifier = _verifier(trusted_root)

    with pytest.raises(StoreVerificationError, match="doğrulanamadı"):
        verifier.verify(
            signed_transaction=_jws(leaf_key, leaf, _payload()),
            expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
            subject_hash="a" * 64,
        )


def test_expired_apple_certificate_is_rejected() -> None:
    root_key, root = _certificate_authority()
    leaf_key, leaf = _leaf(root_key, root)
    verifier = AppStoreVerifier(
        trusted_root=root,
        bundle_id="com.team120.maki.makiApp",
        allowed_products=frozenset({"maki_debt_pro"}),
        environment="Production",
        clock=lambda: NOW + timedelta(days=400),
    )

    with pytest.raises(StoreVerificationError, match="süresi"):
        verifier.verify(
            signed_transaction=_jws(leaf_key, leaf, _payload()),
            expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
            subject_hash="a" * 64,
        )


def test_wrong_apple_algorithm_is_rejected() -> None:
    root_key, root = _certificate_authority()
    leaf_key, leaf = _leaf(root_key, root)
    signed = _jws(leaf_key, leaf, _payload())
    _, payload, signature = signed.split(".")
    invalid_header = _encode(
        {
            "alg": "HS256",
            "x5c": [base64.b64encode(leaf.public_bytes(serialization.Encoding.DER)).decode()],
        }
    )

    with pytest.raises(StoreVerificationError, match="başlığı"):
        _verifier(root).verify(
            signed_transaction=f"{invalid_header}.{payload}.{signature}",
            expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
            subject_hash="a" * 64,
        )


def test_apple_refund_revokes_entitlement() -> None:
    root_key, root = _certificate_authority()
    leaf_key, leaf = _leaf(root_key, root)
    payload = {
        **_payload(),
        "revocationDate": int(NOW.timestamp() * 1_000),
        "revocationReason": 1,
    }

    transaction = _verifier(root).verify(
        signed_transaction=_jws(leaf_key, leaf, payload),
        expected_account_token="11111111-1111-4111-8111-111111111111",  # noqa: S106
        subject_hash="a" * 64,
    )

    assert transaction.event is StoreEvent.REFUNDED


def _verifier(root: x509.Certificate) -> AppStoreVerifier:
    return AppStoreVerifier(
        trusted_root=root,
        bundle_id="com.team120.maki.makiApp",
        allowed_products=frozenset({"maki_debt_pro"}),
        environment="Production",
        clock=lambda: NOW,
    )


def _certificate_authority() -> tuple[ec.EllipticCurvePrivateKey, x509.Certificate]:
    key = ec.generate_private_key(ec.SECP256R1())
    name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "Test Apple Root")])
    certificate = (
        x509.CertificateBuilder()
        .subject_name(name)
        .issuer_name(name)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(NOW - timedelta(days=1))
        .not_valid_after(NOW + timedelta(days=365))
        .add_extension(x509.BasicConstraints(ca=True, path_length=1), critical=True)
        .sign(key, hashes.SHA256())
    )
    return key, certificate


def _leaf(
    root_key: ec.EllipticCurvePrivateKey,
    root: x509.Certificate,
) -> tuple[ec.EllipticCurvePrivateKey, x509.Certificate]:
    key = ec.generate_private_key(ec.SECP256R1())
    certificate = (
        x509.CertificateBuilder()
        .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "App Store")]))
        .issuer_name(root.subject)
        .public_key(key.public_key())
        .serial_number(x509.random_serial_number())
        .not_valid_before(NOW - timedelta(days=1))
        .not_valid_after(NOW + timedelta(days=30))
        .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
        .sign(root_key, hashes.SHA256())
    )
    return key, certificate


def _jws(
    key: ec.EllipticCurvePrivateKey,
    leaf: x509.Certificate,
    payload: dict[str, object],
) -> str:
    header = _encode(
        {
            "alg": "ES256",
            "x5c": [base64.b64encode(leaf.public_bytes(serialization.Encoding.DER)).decode()],
        }
    )
    payload_text = _encode(payload)
    signing_input = f"{header}.{payload_text}".encode()
    der_signature = key.sign(signing_input, ec.ECDSA(hashes.SHA256()))
    left, right = decode_dss_signature(der_signature)
    signature = left.to_bytes(32, "big") + right.to_bytes(32, "big")
    return f"{header}.{payload_text}.{_encode_bytes(signature)}"


def _payload() -> dict[str, object]:
    document: object = json.loads(FIXTURE.read_text(encoding="utf-8"))
    assert isinstance(document, dict)
    return cast("dict[str, object]", document)


def _encode(value: object) -> str:
    return _encode_bytes(json.dumps(value, separators=(",", ":"), sort_keys=True).encode())


def _encode_bytes(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode()
