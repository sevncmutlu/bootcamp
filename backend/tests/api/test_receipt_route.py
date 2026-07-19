from httpx import ASGITransport, AsyncClient

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings

from .job_fakes import (
    FakeJobService,
    FakeTokenVerifier,
    authorization_headers,
)


class MemoryReceiptIngress:
    def __init__(self) -> None:
        self.content: bytes | None = None

    async def put(
        self,
        *,
        owner_id: str,
        content: bytes,
        media_type: str,
    ) -> str:
        del owner_id, media_type
        self.content = content
        return "01K00000000000000000000000"


async def test_receipt_route_stores_only_ephemeral_reference_in_job() -> None:
    jobs = FakeJobService()
    ingress = MemoryReceiptIngress()
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(
            job_service=jobs,
            token_verifier=FakeTokenVerifier(),
            receipt_ingress=ingress,
        ),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/receipts/jobs",
            headers=authorization_headers(),
            files={"file": ("fis.png", b"\x89PNG\r\n\x1a\nicerik", "image/png")},
        )

    assert response.status_code == 202
    assert ingress.content == b"\x89PNG\r\n\x1a\nicerik"
    assert jobs.calls[0][1] == {
        "object_ref": "01K00000000000000000000000",
        "media_type": "image/png",
    }
