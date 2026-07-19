from httpx import ASGITransport, AsyncClient

from maki.bootstrap import create_runtime_app


async def test_runtime_bootstrap_can_start_without_live_adapters_in_test(
    monkeypatch,
) -> None:
    monkeypatch.setenv("MAKI_ENVIRONMENT", "test")
    monkeypatch.delenv("MAKI_DATABASE__DSN", raising=False)
    monkeypatch.delenv("MAKI_REDIS__DSN", raising=False)
    monkeypatch.delenv("MAKI_TELEMETRY__OTLP_ENDPOINT", raising=False)

    app = create_runtime_app()
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health/live")

    assert response.status_code == 200
    assert app.state.container.telemetry is not None
    assert app.state.settings.environment.value == "test"
