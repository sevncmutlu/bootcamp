import asyncio
from enum import StrEnum

from fastapi import APIRouter, Request, Response

from maki.api.dependencies import Container, ReadinessProbe
from maki.common.models import ApiModel

router = APIRouter(prefix="/health", tags=["sağlık"])
_READINESS_TIMEOUT_SECONDS = 0.25


class DependencyStatus(StrEnum):
    READY = "hazir"
    NOT_READY = "hazir_degil"
    TIMED_OUT = "zaman_asimi"


class DependencyHealth(ApiModel):
    ad: str
    durum: DependencyStatus


class LivenessResponse(ApiModel):
    durum: str = "canli"


class ReadinessResponse(ApiModel):
    durum: str
    bagimliliklar: tuple[DependencyHealth, ...]


@router.get(
    "/live",
    operation_id="health_live",
    description="Sürecin yanıt verebildiğini denetler.",
)
async def liveness() -> LivenessResponse:
    return LivenessResponse()


@router.get(
    "/ready",
    operation_id="health_ready",
    description="Zorunlu bağımlılıkların hazır olduğunu denetler.",
    responses={503: {"description": "En az bir zorunlu bağımlılık hazır değil."}},
)
async def readiness(request: Request, response: Response) -> ReadinessResponse:
    container: Container = request.app.state.container
    dependencies = tuple(
        await asyncio.gather(*(_check_probe(probe) for probe in container.readiness_probes))
    )
    is_ready = all(item.durum is DependencyStatus.READY for item in dependencies)
    if not is_ready:
        response.status_code = 503
    return ReadinessResponse(
        durum="hazir" if is_ready else "hazir_degil",
        bagimliliklar=dependencies,
    )


async def _check_probe(probe: ReadinessProbe) -> DependencyHealth:
    try:
        async with asyncio.timeout(_READINESS_TIMEOUT_SECONDS):
            ready = await probe.is_ready()
    except TimeoutError:
        status = DependencyStatus.TIMED_OUT
    except Exception:  # noqa: BLE001
        # Sağlık yanıtına sağlayıcı hatası sızdırılmaz.
        status = DependencyStatus.NOT_READY
    else:
        status = DependencyStatus.READY if ready else DependencyStatus.NOT_READY
    return DependencyHealth(ad=probe.name, durum=status)
