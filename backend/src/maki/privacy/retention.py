from datetime import datetime, timedelta
from enum import StrEnum

from pydantic import Field

from maki.common.models import ApiModel


class RetentionDataClass(StrEnum):
    IDEMPOTENCY = "idempotency"
    JOB_METADATA = "job_metadata"
    OCR_RESULT = "ocr_result"
    TELEMETRY = "telemetry"


class RetentionPolicy(ApiModel):
    idempotency_ttl: timedelta = Field(
        default=timedelta(hours=24),
        gt=timedelta(0),
        le=timedelta(days=7),
    )
    job_metadata_ttl: timedelta = Field(
        default=timedelta(days=7),
        gt=timedelta(0),
        le=timedelta(days=30),
    )
    ocr_result_ttl: timedelta = Field(
        default=timedelta(minutes=10),
        gt=timedelta(0),
        le=timedelta(hours=1),
    )
    telemetry_ttl: timedelta = Field(
        default=timedelta(days=14),
        gt=timedelta(0),
        le=timedelta(days=30),
    )

    @property
    def data_classes(self) -> tuple[RetentionDataClass, ...]:
        return tuple(RetentionDataClass)

    def cutoff(
        self,
        *,
        data_class: RetentionDataClass,
        now: datetime,
    ) -> datetime:
        if now.utcoffset() is None:
            msg = "Saklama hesabı saat dilimi taşımalıdır."
            raise ValueError(msg)
        return now - self._duration(data_class)

    def is_expired(
        self,
        *,
        data_class: RetentionDataClass,
        recorded_at: datetime,
        now: datetime,
    ) -> bool:
        if recorded_at.utcoffset() is None:
            msg = "Saklama kayıt zamanı saat dilimi taşımalıdır."
            raise ValueError(msg)
        return recorded_at <= self.cutoff(data_class=data_class, now=now)

    def _duration(self, data_class: RetentionDataClass) -> timedelta:
        if data_class is RetentionDataClass.IDEMPOTENCY:
            return self.idempotency_ttl
        if data_class is RetentionDataClass.JOB_METADATA:
            return self.job_metadata_ttl
        if data_class is RetentionDataClass.OCR_RESULT:
            return self.ocr_result_ttl
        return self.telemetry_ttl
