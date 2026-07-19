import asyncio

from maki.coach.anthropic_adapter import AnthropicAdapter
from maki.coach.retrieval import OfficialSourceRetriever
from maki.coach.service import CoachService
from maki.coach.source_repository import SqlAlchemySourceCardRepository
from maki.jobs.domain_handlers import CoachDomainJobHandler
from maki.jobs.models import JobKind
from maki.privacy.scrubber import TextScrubber
from maki.workers.worker_bootstrap import (
    ProcessNotConfiguredError,
    WorkerResources,
    run_specialized_worker,
)


def main() -> None:
    raise SystemExit(
        asyncio.run(
            run_specialized_worker(
                kind=JobKind.COACH,
                handler_factory=_handler,
            )
        )
    )


def _handler(resources: WorkerResources) -> CoachDomainJobHandler:
    api_key = resources.settings.anthropic_api_key
    if api_key is None:
        raise ProcessNotConfiguredError
    service = CoachService(
        scrubber=TextScrubber(),
        retriever=OfficialSourceRetriever(
            SqlAlchemySourceCardRepository(resources.database.session_factory)
        ),
        provider=AnthropicAdapter.from_credentials(
            api_key=api_key.get_secret_value(),
            model_name=resources.settings.anthropic_model,
        ),
    )
    return CoachDomainJobHandler(service, resources.results)


if __name__ == "__main__":
    main()
