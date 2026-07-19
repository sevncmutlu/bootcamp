from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import InMemorySpanExporter

from maki.observability.telemetry import Telemetry


def test_queue_trace_context_creates_child_without_payload_attributes() -> None:
    exporter = InMemorySpanExporter()
    provider = TracerProvider()
    provider.add_span_processor(SimpleSpanProcessor(exporter))
    telemetry = Telemetry(
        tracer=provider.get_tracer("test"),
        meter=None,
    )

    with telemetry.span("maki.api.accept", {"job.kind": "forecast"}):
        traceparent = telemetry.current_traceparent()

    assert traceparent is not None
    with telemetry.span(
        "maki.worker.execute",
        {"job.kind": "forecast", "amount": 5_000},
        traceparent=traceparent,
    ):
        pass

    spans = exporter.get_finished_spans()
    parent = next(span for span in spans if span.name == "maki.api.accept")
    child = next(span for span in spans if span.name == "maki.worker.execute")
    assert child.context.trace_id == parent.context.trace_id
    assert child.parent is not None
    assert child.parent.span_id == parent.context.span_id
    assert dict(child.attributes or {}) == {"job.kind": "forecast"}
