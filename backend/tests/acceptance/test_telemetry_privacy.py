from httpx import ASGITransport, AsyncClient
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import InMemoryMetricReader
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter

from maki.api.app import create_app
from maki.api.dependencies import Container
from maki.common.config import Environment, Settings
from maki.observability.telemetry import Telemetry


async def test_negative_request_exports_only_low_cardinality_metadata() -> None:
    exporter = InMemorySpanExporter()
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    metric_reader = InMemoryMetricReader()
    meter_provider = MeterProvider(metric_readers=[metric_reader])
    telemetry = Telemetry(
        tracer=provider.get_tracer("acceptance"),
        meter=meter_provider.get_meter("acceptance"),
    )
    app = create_app(
        Settings(environment=Environment.TEST),
        Container(telemetry=telemetry),
    )
    transport = ASGITransport(app=app, raise_app_exceptions=False)

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/api/v1/coach/queries",
            headers={"Idempotency-Key": "telemetry-gizlilik"},
            json={
                "question": "emir@example.com",
                "merchant_name": "Gizli Market",
                "iban": "TR330006100519786457841326",
                "amount": 1_250,
            },
        )

    assert response.status_code == 422
    span = exporter.get_finished_spans()[0]
    assert dict(span.attributes or {}) == {
        "error.code": "GIZLILIK_ALANI_REDDEDILDI",
        "http.request.method": "POST",
        "http.response.status_code": 422,
        "http.route": "/api/v1/coach/queries",
    }
    exported = repr((span.name, span.attributes, span.events, span.status))
    for private_value in (
        "emir@example.com",
        "Gizli Market",
        "TR330006100519786457841326",
        "1250",
    ):
        assert private_value not in exported

    metrics = metric_reader.get_metrics_data()
    privacy_metric = next(
        metric
        for resource in metrics.resource_metrics
        for scope in resource.scope_metrics
        for metric in scope.metrics
        if metric.name == "maki.privacy.rejected"
    )
    points = privacy_metric.data.data_points
    assert sum(point.value for point in points) == 1
    assert dict(points[0].attributes) == {
        "http.route": "/api/v1/coach/queries",
    }
