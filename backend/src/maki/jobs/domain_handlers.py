from __future__ import annotations

from typing import TYPE_CHECKING, Protocol

from pydantic import Field, JsonValue, ValidationError

from maki.coach.models import CoachQuery
from maki.coach.ports import CoachProviderError
from maki.common.models import ApiModel
from maki.forecast.models import RelativeSeries  # noqa: TC001
from maki.jobs.results import (
    CoachJobResult,
    ForecastJobResult,
    JobResult,
    ReceiptJobResult,
)
from maki.workers.runtime import PermanentJobError, TransientJobError

if TYPE_CHECKING:
    from maki.coach.models import CoachAnswer
    from maki.forecast.service import ForecastResult
    from maki.jobs.models import JobRecord
    from maki.ocr.models import ReceiptResult

_RECEIPT_EXPIRED_CODE = "FIS_GORSELI_SURESI_DOLDU"
_INVALID_PAYLOAD_CODE = "IS_GIRDISI_GECERSIZ"


class CoachPort(Protocol):
    async def answer(self, query: CoachQuery) -> CoachAnswer: ...


class ForecastPort(Protocol):
    async def forecast(
        self,
        *,
        series: RelativeSeries,
        horizon: int,
    ) -> ForecastResult: ...


class ReceiptPort(Protocol):
    async def handle(
        self,
        job_id: str,
        image_bytes: bytes,
    ) -> ReceiptResult: ...


class ReceiptBlobReader(Protocol):
    async def take(self, object_ref: str) -> bytes | None: ...


class ResultWriter(Protocol):
    async def put(self, job_id: str, result: JobResult) -> None: ...


class ForecastWorkItem(ApiModel):
    series: RelativeSeries
    horizon: int = Field(ge=1, le=90)


class ReceiptWorkItem(ApiModel):
    object_ref: str = Field(pattern=r"^[0-9A-HJKMNP-TV-Z]{26}$")
    media_type: str = Field(pattern=r"^image/(jpeg|png)$")


class CoachDomainJobHandler:
    def __init__(self, service: CoachPort, results: ResultWriter) -> None:
        self._service = service
        self._results = results

    async def __call__(self, job: JobRecord) -> None:
        query = _parse(CoachQuery, job.payload)
        try:
            answer = await self._service.answer(query)
        except CoachProviderError as error:
            exception = TransientJobError if error.retryable else PermanentJobError
            raise exception(error.code) from error
        await self._results.put(
            job.job_id,
            CoachJobResult(
                kind="coach",
                schema_version=1,
                answer=answer,
            ),
        )


class ForecastDomainJobHandler:
    def __init__(self, service: ForecastPort, results: ResultWriter) -> None:
        self._service = service
        self._results = results

    async def __call__(self, job: JobRecord) -> None:
        work = _parse(ForecastWorkItem, job.payload)
        forecast = await self._service.forecast(
            series=work.series,
            horizon=work.horizon,
        )
        await self._results.put(
            job.job_id,
            ForecastJobResult(
                kind="forecast",
                schema_version=1,
                forecast=forecast,
            ),
        )


class ReceiptDomainJobHandler:
    def __init__(
        self,
        service: ReceiptPort,
        blobs: ReceiptBlobReader,
        results: ResultWriter,
    ) -> None:
        self._service = service
        self._blobs = blobs
        self._results = results

    async def __call__(self, job: JobRecord) -> None:
        work = _parse(ReceiptWorkItem, job.payload)
        image = await self._blobs.take(work.object_ref)
        if image is None:
            raise PermanentJobError(_RECEIPT_EXPIRED_CODE)
        receipt = await self._service.handle(job.job_id, image)
        await self._results.put(
            job.job_id,
            ReceiptJobResult(
                kind="receipt",
                schema_version=1,
                receipt=receipt,
            ),
        )


def _parse[ModelT: ApiModel](
    model: type[ModelT],
    payload: dict[str, JsonValue],
) -> ModelT:
    try:
        return model.model_validate(payload)
    except ValidationError:
        raise PermanentJobError(_INVALID_PAYLOAD_CODE) from None
