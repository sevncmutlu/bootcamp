import asyncio

from maki.forecast.baselines import NaiveForecaster, SeasonalNaiveForecaster
from maki.forecast.cache import RedisForecastCache
from maki.forecast.prophet_adapter import ProphetAdapter
from maki.forecast.service import ForecastService
from maki.jobs.domain_handlers import ForecastDomainJobHandler
from maki.jobs.models import JobKind
from maki.workers.worker_bootstrap import WorkerResources, run_specialized_worker


def main() -> None:
    raise SystemExit(
        asyncio.run(
            run_specialized_worker(
                kind=JobKind.FORECAST,
                handler_factory=_handler,
            )
        )
    )


def _handler(resources: WorkerResources) -> ForecastDomainJobHandler:
    service = ForecastService(
        baselines=(NaiveForecaster(), SeasonalNaiveForecaster()),
        candidates=(ProphetAdapter(),),
        cache=RedisForecastCache(resources.redis),
        code_version="forecast-v1",
        settings_version="forecast-default-v1",
    )
    return ForecastDomainJobHandler(service, resources.results)


if __name__ == "__main__":
    main()
