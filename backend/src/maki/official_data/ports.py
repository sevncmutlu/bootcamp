from datetime import datetime
from typing import Protocol

from maki.official_data.models import SourceSnapshot


class OfficialDataRepository(Protocol):
    async def find_by_identity(
        self,
        source_name: str,
        source_version: str,
        content_sha256: str,
    ) -> SourceSnapshot | None: ...

    async def latest_published(self, source_name: str) -> SourceSnapshot | None: ...

    async def publish(
        self,
        snapshot: SourceSnapshot,
        published_at: datetime,
    ) -> SourceSnapshot: ...
