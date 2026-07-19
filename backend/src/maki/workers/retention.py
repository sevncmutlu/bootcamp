from collections.abc import Callable
from datetime import datetime
from typing import Protocol

from maki.common.models import ApiModel
from maki.privacy.retention import RetentionDataClass, RetentionPolicy

_MAXIMUM_BATCH_SIZE = 10_000


class RetentionBackend(Protocol):
    async def purge_before(
        self,
        *,
        data_class: RetentionDataClass,
        cutoff: datetime,
        batch_size: int,
    ) -> int: ...


class RetentionResult(ApiModel):
    deleted: dict[RetentionDataClass, int]


class RetentionWorker:
    def __init__(
        self,
        *,
        backend: RetentionBackend,
        policy: RetentionPolicy,
        clock: Callable[[], datetime],
        batch_size: int = 1_000,
        on_purge: Callable[[RetentionDataClass, int], None] | None = None,
        data_classes: tuple[RetentionDataClass, ...] | None = None,
    ) -> None:
        if not 1 <= batch_size <= _MAXIMUM_BATCH_SIZE:
            msg = "Saklama toplu işlem boyutu 1 ile 10000 arasında olmalıdır."
            raise ValueError(msg)
        self._backend = backend
        self._policy = policy
        self._clock = clock
        self._batch_size = batch_size
        self._on_purge = on_purge
        self._data_classes = data_classes or policy.data_classes

    async def run(self) -> RetentionResult:
        now = self._clock()
        deleted: dict[RetentionDataClass, int] = {}
        for data_class in self._data_classes:
            count = await self._purge_class(data_class, now)
            deleted[data_class] = count
            if count and self._on_purge is not None:
                self._on_purge(data_class, count)
        return RetentionResult(deleted=deleted)

    async def _purge_class(
        self,
        data_class: RetentionDataClass,
        now: datetime,
    ) -> int:
        total = 0
        cutoff = self._policy.cutoff(data_class=data_class, now=now)
        while True:
            count = await self._backend.purge_before(
                data_class=data_class,
                cutoff=cutoff,
                batch_size=self._batch_size,
            )
            if not 0 <= count <= self._batch_size:
                msg = "Saklama deposu geçersiz silme sayısı döndürdü."
                raise RuntimeError(msg)
            total += count
            if count < self._batch_size:
                return total
