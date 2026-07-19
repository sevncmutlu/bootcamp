from datetime import date, datetime
from decimal import Decimal

from pydantic import JsonValue
from sqlalchemy import (
    JSON,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    MetaData,
    Numeric,
    String,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

_NAMING_CONVENTION = {
    "ix": "ix_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}
_JSON_TYPE = JSON().with_variant(JSONB(), "postgresql")
_JOB_STATUSES = "'accepted','queued','running','retry_wait','succeeded','failed'"
_JOB_KINDS = "'coach','forecast','receipt','model_training','billing_verification','retention'"
_PUBLICATION_STATES = "'staged','published'"


class Base(DeclarativeBase):
    metadata = MetaData(naming_convention=_NAMING_CONVENTION)


class JobTable(Base):
    __tablename__ = "jobs"
    __table_args__ = (
        CheckConstraint(f"status IN ({_JOB_STATUSES})", name="status_allowed"),
        CheckConstraint(f"kind IN ({_JOB_KINDS})", name="kind_allowed"),
        CheckConstraint("attempt >= 0", name="attempt_nonnegative"),
        CheckConstraint("version >= 0", name="version_nonnegative"),
        Index("ix_jobs_status_created_at", "status", "created_at"),
        Index("ix_jobs_owner_hash_created_at", "owner_hash", "created_at"),
    )

    job_id: Mapped[str] = mapped_column(String(26), primary_key=True)
    kind: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(24), nullable=False)
    owner_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    payload: Mapped[dict[str, JsonValue]] = mapped_column(_JSON_TYPE, nullable=False)
    payload_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    completed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    failure_code: Mapped[str | None] = mapped_column(String(64))
    lease_token: Mapped[str | None] = mapped_column(String(26))
    lease_expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    attempt: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=0)


class OutboxEventTable(Base):
    __tablename__ = "outbox_events"
    __table_args__ = (
        UniqueConstraint(
            "job_id",
            "topic",
            "event_version",
            name="uq_outbox_events_job_topic_version",
        ),
        Index(
            "ix_outbox_events_unpublished",
            "created_at",
            postgresql_where=text("published_at IS NULL"),
        ),
    )

    event_id: Mapped[str] = mapped_column(String(26), primary_key=True)
    job_id: Mapped[str] = mapped_column(
        String(26),
        ForeignKey("jobs.job_id", ondelete="CASCADE"),
        nullable=False,
    )
    topic: Mapped[str] = mapped_column(String(96), nullable=False)
    event_version: Mapped[int] = mapped_column(Integer, nullable=False)
    payload: Mapped[dict[str, JsonValue]] = mapped_column(_JSON_TYPE, nullable=False)
    traceparent: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class IdempotencyKeyTable(Base):
    __tablename__ = "idempotency_keys"
    __table_args__ = (Index("ix_idempotency_keys_created_at", "created_at"),)

    key_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    payload_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    job_id: Mapped[str] = mapped_column(
        String(26),
        ForeignKey("jobs.job_id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class SourceSnapshotTable(Base):
    __tablename__ = "source_snapshots"
    __table_args__ = (
        CheckConstraint(
            f"state IN ({_PUBLICATION_STATES})",
            name="state_allowed",
        ),
        CheckConstraint("point_count > 0", name="point_count_positive"),
        UniqueConstraint(
            "source_name",
            "source_version",
            "content_sha256",
            name="uq_source_snapshots_identity",
        ),
        Index(
            "ix_source_snapshots_source_published",
            "source_name",
            "published_at",
        ),
    )

    snapshot_id: Mapped[str] = mapped_column(String(26), primary_key=True)
    source_name: Mapped[str] = mapped_column(String(32), nullable=False)
    source_version: Mapped[str] = mapped_column(String(128), nullable=False)
    schema_version: Mapped[int] = mapped_column(Integer, nullable=False)
    content_sha256: Mapped[str] = mapped_column(String(64), nullable=False)
    etag: Mapped[str | None] = mapped_column(String(512))
    state: Mapped[str] = mapped_column(String(16), nullable=False)
    point_count: Mapped[int] = mapped_column(Integer, nullable=False)
    staged_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))


class SeriesPointTable(Base):
    __tablename__ = "series_points"
    __table_args__ = (
        CheckConstraint(
            "frequency IN ('monthly','daily')",
            name="frequency_allowed",
        ),
    )

    snapshot_id: Mapped[str] = mapped_column(
        String(26),
        ForeignKey("source_snapshots.snapshot_id", ondelete="CASCADE"),
        primary_key=True,
    )
    series_id: Mapped[str] = mapped_column(String(64), primary_key=True)
    period: Mapped[date] = mapped_column(Date, primary_key=True)
    value: Mapped[Decimal] = mapped_column(Numeric(38, 18), nullable=False)
    unit: Mapped[str] = mapped_column(String(32), nullable=False)
    frequency: Mapped[str] = mapped_column(String(16), nullable=False)
    release_date: Mapped[date] = mapped_column(Date, nullable=False)
    source_url: Mapped[str] = mapped_column(String(2048), nullable=False)
    retrieved_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class SourcePublicationTable(Base):
    __tablename__ = "source_publications"

    source_name: Mapped[str] = mapped_column(String(32), primary_key=True)
    snapshot_id: Mapped[str] = mapped_column(
        String(26),
        ForeignKey("source_snapshots.snapshot_id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    published_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class LeaderboardContributionTable(Base):
    __tablename__ = "leaderboard_contributions"
    __table_args__ = (
        CheckConstraint(
            "score_basis_points BETWEEN 0 AND 10000",
            name="score_basis_points_range",
        ),
        Index(
            "ix_leaderboard_cohort_expiry_score",
            "cohort_hash",
            "expires_at",
            "score_basis_points",
        ),
    )

    cohort_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    subject_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    contribution_day: Mapped[date] = mapped_column(Date, primary_key=True)
    score_basis_points: Mapped[int] = mapped_column(Integer, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class StoreTransactionTable(Base):
    __tablename__ = "store_transactions"
    __table_args__ = (
        Index(
            "ix_store_transactions_subject_occurred",
            "subject_hash",
            "occurred_at",
        ),
    )

    event_id: Mapped[str] = mapped_column(String(256), primary_key=True)
    store: Mapped[str] = mapped_column(String(24), nullable=False)
    transaction_id: Mapped[str] = mapped_column(String(256), nullable=False)
    original_transaction_id: Mapped[str] = mapped_column(String(256), nullable=False)
    product_id: Mapped[str] = mapped_column(String(128), nullable=False)
    subject_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    event: Mapped[str] = mapped_column(String(32), nullable=False)
    event_version: Mapped[int] = mapped_column(Integer, nullable=False)
    occurred_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    event_sha256: Mapped[str] = mapped_column(String(64), nullable=False)


class EntitlementTable(Base):
    __tablename__ = "entitlements"

    subject_hash: Mapped[str] = mapped_column(String(64), primary_key=True)
    product_id: Mapped[str] = mapped_column(String(128), primary_key=True)
    store: Mapped[str] = mapped_column(String(24), nullable=False)
    status: Mapped[str] = mapped_column(String(24), nullable=False)
    original_transaction_id: Mapped[str] = mapped_column(String(256), nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_event_id: Mapped[str] = mapped_column(
        String(256),
        ForeignKey("store_transactions.event_id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    last_event: Mapped[str] = mapped_column(String(32), nullable=False)
    last_event_version: Mapped[int] = mapped_column(Integer, nullable=False)
    last_event_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
