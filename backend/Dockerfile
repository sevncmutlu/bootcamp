# syntax=docker/dockerfile:1.7

ARG PYTHON_IMAGE=python:3.12.13-slim-bookworm
ARG UV_IMAGE=ghcr.io/astral-sh/uv:0.11.29

FROM ${UV_IMAGE} AS uv

FROM ${PYTHON_IMAGE} AS builder-base
COPY --from=uv /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy
WORKDIR /app
COPY pyproject.toml uv.lock README.md ./

FROM builder-base AS dependencies-core
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

FROM dependencies-core AS builder-core
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

FROM builder-base AS dependencies-api
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra billing --no-install-project

FROM dependencies-api AS builder-api
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra billing --no-editable

FROM builder-base AS dependencies-coach
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra coach --no-install-project

FROM dependencies-coach AS builder-coach
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra coach --no-editable

FROM builder-base AS dependencies-forecast
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra forecast --no-install-project

FROM dependencies-forecast AS builder-forecast
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra forecast --no-editable

FROM builder-base AS dependencies-ocr
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra ocr --no-install-project

FROM dependencies-ocr AS builder-ocr
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --extra ocr --no-editable

FROM ${PYTHON_IMAGE} AS runtime-core
ENV PATH="/app/.venv/bin:${PATH}" \
    HOME=/tmp \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 10001 maki \
    && useradd --uid 10001 --gid 10001 --no-create-home \
        --shell /usr/sbin/nologin maki
WORKDIR /app

FROM runtime-core AS runtime-ml
RUN apt-get update \
    && apt-get install --yes --no-install-recommends libgomp1 \
    && rm -rf /var/lib/apt/lists/*

FROM runtime-core AS api
COPY --from=builder-api /app/.venv /app/.venv
COPY alembic.ini ./
COPY alembic ./alembic
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=2)"]
ENTRYPOINT ["python", "-m", "uvicorn"]
CMD ["maki.bootstrap:create_runtime_app", "--factory", "--host=0.0.0.0", "--port=8000", "--no-access-log"]

FROM runtime-core AS dispatcher
COPY --from=builder-core /app/.venv /app/.venv
USER 10001:10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-m", "maki.workers.health"]
ENTRYPOINT ["python", "-m", "maki.workers.dispatcher_main"]

FROM runtime-core AS worker-coach
COPY --from=builder-coach /app/.venv /app/.venv
USER 10001:10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-m", "maki.workers.health"]
ENTRYPOINT ["python", "-m", "maki.workers.coach_main"]

FROM runtime-ml AS worker-forecast
COPY --from=builder-forecast /app/.venv /app/.venv
USER 10001:10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD ["python", "-m", "maki.workers.health"]
ENTRYPOINT ["python", "-m", "maki.workers.forecast_main"]

FROM runtime-ml AS worker-ocr
COPY --from=builder-ocr /app/.venv /app/.venv
USER 10001:10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD ["python", "-m", "maki.workers.health"]
ENTRYPOINT ["python", "-m", "maki.workers.receipt_main"]

FROM runtime-core AS worker-data
COPY --from=builder-core /app/.venv /app/.venv
USER 10001:10001
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-m", "maki.workers.health"]
ENTRYPOINT ["python", "-m", "maki.workers.data_main"]

FROM api AS default
