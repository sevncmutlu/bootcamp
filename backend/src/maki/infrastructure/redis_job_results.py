from pydantic import TypeAdapter, ValidationError
from redis.asyncio import Redis
from redis.exceptions import RedisError

from maki.jobs.models import JobKind
from maki.jobs.results import JobResult

_RESULT_ADAPTER: TypeAdapter[JobResult] = TypeAdapter(JobResult)
_SEVEN_DAYS_SECONDS = 7 * 24 * 60 * 60
_RECEIPT_TTL_SECONDS = 600


class ResultStoreUnavailableError(RuntimeError):
    pass


class RedisJobResultRepository:
    def __init__(self, client: Redis) -> None:
        self._client = client

    async def put(self, job_id: str, result: JobResult) -> None:
        ttl = _RECEIPT_TTL_SECONDS if result.kind == JobKind.RECEIPT.value else _SEVEN_DAYS_SECONDS
        try:
            await self._client.set(
                _key(job_id),
                _RESULT_ADAPTER.dump_json(result),
                ex=ttl,
            )
        except RedisError as error:
            raise ResultStoreUnavailableError from error

    async def get(
        self,
        job_id: str,
        kind: JobKind,
    ) -> JobResult | None:
        try:
            value = (
                await self._client.getdel(_key(job_id))
                if kind is JobKind.RECEIPT
                else await self._client.get(_key(job_id))
            )
        except RedisError as error:
            raise ResultStoreUnavailableError from error
        if value is None:
            return None
        try:
            result = _RESULT_ADAPTER.validate_json(value)
        except ValidationError as error:
            raise ResultStoreUnavailableError from error
        if result.kind != kind.value:
            raise ResultStoreUnavailableError
        return result


def _key(job_id: str) -> str:
    return f"maki:job-result:v1:{job_id}"
