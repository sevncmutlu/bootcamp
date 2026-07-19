from datetime import UTC, datetime

from maki.jobs.models import JobKind, JobRecord
from maki.security.tokens import TokenClaims

NOW = datetime(2026, 7, 19, 12, tzinfo=UTC)
TOKEN = "gecerli-test-token"  # noqa: S105


class FakeTokenVerifier:
    def verify(self, token: str) -> TokenClaims:
        if token != TOKEN:
            msg = "Oturum belirteci geçersiz."
            raise ValueError(msg)
        return TokenClaims(
            sub="cihaz-1",
            jti="01K00000000000000000000000",
            iss="maki",
            aud="maki-mobile",
            iat=1,
            nbf=1,
            exp=4_102_444_800,
        )


class FakeJobService:
    def __init__(self) -> None:
        self.calls: list[tuple[JobKind, dict[str, object], str, str]] = []

    async def accept(
        self,
        kind: JobKind,
        payload: dict[str, object],
        owner_id: str,
        idempotency_key: str,
    ) -> JobRecord:
        self.calls.append((kind, payload, owner_id, idempotency_key))
        return JobRecord.new(
            kind=kind,
            owner_hash="a" * 64,
            payload=payload,
            payload_hash="b" * 64,
            now=NOW,
        )


def authorization_headers() -> dict[str, str]:
    return {
        "Authorization": f"Bearer {TOKEN}",
        "Idempotency-Key": "benzersiz-anahtar",
    }
