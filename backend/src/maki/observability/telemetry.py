import re
from collections.abc import Iterator, Mapping
from contextlib import contextmanager

from opentelemetry import metrics, trace
from opentelemetry.context import Context
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.metrics import Counter, Histogram, Meter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.trace.sampling import ParentBased, TraceIdRatioBased
from opentelemetry.trace import Tracer
from opentelemetry.trace.propagation.tracecontext import TraceContextTextMapPropagator

from maki.common.config import Environment, TelemetrySettings
from maki.observability.attributes import AttributeValue, safe_attributes

_SPAN_NAME = re.compile(r"^maki\.[a-z0-9_.-]{1,80}$")
_MAXIMUM_COUNTER_INCREMENT = 1_000_000_000
_COUNTER_NAMES = frozenset(
    {
        "maki.attribute.dropped",
        "maki.http.requests",
        "maki.jobs.accepted",
        "maki.jobs.completed",
        "maki.privacy.rejected",
        "maki.provider.failures",
        "maki.retention.deleted",
    }
)
_HISTOGRAM_NAMES = frozenset(
    {
        "maki.http.duration_ms",
        "maki.job.duration_ms",
        "maki.provider.duration_ms",
        "maki.queue.age_ms",
    }
)


class Telemetry:
    def __init__(
        self,
        *,
        tracer: Tracer,
        meter: Meter | None,
        tracer_provider: TracerProvider | None = None,
        meter_provider: MeterProvider | None = None,
    ) -> None:
        self._tracer = tracer
        self._meter = meter
        self._tracer_provider = tracer_provider
        self._meter_provider = meter_provider
        self._counters: dict[str, Counter] = {}
        self._histograms: dict[str, Histogram] = {}

    @contextmanager
    def span(
        self,
        name: str,
        attributes: Mapping[str, object] | None = None,
        *,
        traceparent: str | None = None,
    ) -> Iterator[None]:
        self._validate_span_name(name)
        context = self._parent_context(traceparent)
        with self._tracer.start_as_current_span(
            name,
            context=context,
            attributes=self._attributes(attributes),
            record_exception=False,
            set_status_on_exception=False,
        ):
            yield

    def increment(
        self,
        name: str,
        attributes: Mapping[str, object] | None = None,
        *,
        amount: int = 1,
    ) -> None:
        if name not in _COUNTER_NAMES:
            msg = "Telemetry sayaç adı izin listesinde değil."
            raise ValueError(msg)
        if not 1 <= amount <= _MAXIMUM_COUNTER_INCREMENT:
            msg = "Telemetry sayaç artışı geçersiz."
            raise ValueError(msg)
        if self._meter is None:
            return
        counter = self._counters.get(name)
        if counter is None:
            counter = self._meter.create_counter(name)
            self._counters[name] = counter
        counter.add(amount, attributes=self._attributes(attributes))

    def observe(
        self,
        name: str,
        value: float,
        attributes: Mapping[str, object] | None = None,
    ) -> None:
        if name not in _HISTOGRAM_NAMES:
            msg = "Telemetry histogram adı izin listesinde değil."
            raise ValueError(msg)
        if self._meter is None:
            return
        histogram = self._histograms.get(name)
        if histogram is None:
            histogram = self._meter.create_histogram(name, unit="ms")
            self._histograms[name] = histogram
        histogram.record(value, attributes=self._attributes(attributes))

    def set_current_span_attributes(
        self,
        attributes: Mapping[str, object],
    ) -> None:
        span = trace.get_current_span()
        for key, value in self._attributes(attributes).items():
            span.set_attribute(key, value)

    @staticmethod
    def current_traceparent() -> str | None:
        carrier: dict[str, str] = {}
        TraceContextTextMapPropagator().inject(carrier)
        return carrier.get("traceparent")

    def shutdown(self) -> None:
        if self._meter_provider is not None:
            self._meter_provider.shutdown()
        if self._tracer_provider is not None:
            self._tracer_provider.shutdown()

    def _attributes(
        self,
        attributes: Mapping[str, object] | None,
    ) -> dict[str, AttributeValue]:
        return safe_attributes(attributes, on_drop=self._attribute_dropped)

    def _attribute_dropped(self, _key: str) -> None:
        if self._meter is None:
            return
        counter = self._counters.get("maki.attribute.dropped")
        if counter is None:
            counter = self._meter.create_counter("maki.attribute.dropped")
            self._counters["maki.attribute.dropped"] = counter
        counter.add(1)

    @staticmethod
    def _parent_context(traceparent: str | None) -> Context | None:
        if traceparent is None:
            return None
        carrier = {"traceparent": traceparent}
        return TraceContextTextMapPropagator().extract(carrier)

    @staticmethod
    def _validate_span_name(name: str) -> None:
        if not _SPAN_NAME.fullmatch(name):
            msg = "Telemetry span adı geçersiz."
            raise ValueError(msg)


def configure_telemetry(
    *,
    settings: TelemetrySettings,
    environment: Environment,
    process_type: str,
    service_version: str,
) -> Telemetry:
    resource = Resource.create(
        {
            "service.name": settings.service_name,
            "service.version": service_version,
            "deployment.environment": environment.value,
            "process.type": process_type,
        }
    )
    tracer_provider = TracerProvider(
        resource=resource,
        sampler=ParentBased(TraceIdRatioBased(settings.trace_sample_ratio)),
    )
    metric_readers = []
    if settings.otlp_endpoint is not None:
        endpoint = str(settings.otlp_endpoint).rstrip("/")
        insecure = endpoint.startswith("http://")
        tracer_provider.add_span_processor(
            BatchSpanProcessor(OTLPSpanExporter(endpoint=endpoint, insecure=insecure))
        )
        metric_readers.append(
            PeriodicExportingMetricReader(OTLPMetricExporter(endpoint=endpoint, insecure=insecure))
        )
    meter_provider = MeterProvider(resource=resource, metric_readers=metric_readers)
    trace.set_tracer_provider(tracer_provider)
    metrics.set_meter_provider(meter_provider)
    return Telemetry(
        tracer=tracer_provider.get_tracer(settings.service_name, service_version),
        meter=meter_provider.get_meter(settings.service_name, service_version),
        tracer_provider=tracer_provider,
        meter_provider=meter_provider,
    )
