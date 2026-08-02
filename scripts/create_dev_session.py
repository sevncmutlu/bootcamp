from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path

import jwt
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from maki.common.ids import new_ulid
from maki.security.tokens import TokenClaims, TokenIssuer


def main() -> int:
    args = _arguments()
    private_key_path = args.key_dir / "maki-dev-private.pem"
    public_key_path = args.key_dir / "maki-dev-public.pem"
    if not private_key_path.exists() or not public_key_path.exists():
        _generate_keys(private_key_path, public_key_path)
    private_key = private_key_path.read_bytes()
    public_key = public_key_path.read_text(encoding="utf-8")
    token = _issue_token(
        private_key=private_key,
        subject=args.subject,
        ttl_seconds=args.ttl_seconds,
    )
    print(json.dumps({"token": token, "public_key": public_key}))
    return 0


def _arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Süreli Maki geliştirme oturumu üretir."
    )
    parser.add_argument("--key-dir", type=Path, required=True)
    parser.add_argument("--subject", default="maki-local-user")
    parser.add_argument("--ttl-seconds", type=int, default=3600)
    args = parser.parse_args()
    if not 300 <= args.ttl_seconds <= 604800:
        parser.error("--ttl-seconds 300 ile 604800 arasında olmalıdır.")
    return args


def _issue_token(*, private_key: bytes, subject: str, ttl_seconds: int) -> str:
    if ttl_seconds <= 3600:
        return TokenIssuer(
            private_key=private_key,
            key_id="development",
            issuer="maki",
            audience="maki-mobile",
            clock=lambda: datetime.now(UTC),
        ).issue(subject=subject, ttl_seconds=ttl_seconds)

    now = int(datetime.now(UTC).timestamp())
    claims = TokenClaims(
        sub=subject,
        jti=new_ulid(),
        iss="maki",
        aud="maki-mobile",
        iat=now,
        nbf=now,
        exp=now + ttl_seconds,
    )
    return jwt.encode(
        claims.model_dump(mode="json"),
        key=private_key,
        algorithm="EdDSA",
        headers={"kid": "development"},
    )


def _generate_keys(private_path: Path, public_path: Path) -> None:
    private_path.parent.mkdir(parents=True, exist_ok=True)
    private_key = Ed25519PrivateKey.generate()
    private_path.write_bytes(
        private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.PKCS8,
            encryption_algorithm=serialization.NoEncryption(),
        )
    )
    public_path.write_bytes(
        private_key.public_key().public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo,
        )
    )


if __name__ == "__main__":
    raise SystemExit(main())
