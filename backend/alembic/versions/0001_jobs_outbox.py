from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision: str = "0001_jobs_outbox"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

_JOB_STATUSES = "'accepted','queued','running','retry_wait','succeeded','failed'"
_JOB_KINDS = "'coach','forecast','receipt','model_training','billing_verification','retention'"


def upgrade() -> None:
    op.create_table(
        "jobs",
        sa.Column("job_id", sa.String(length=26), nullable=False),
        sa.Column("kind", sa.String(length=32), nullable=False),
        sa.Column("status", sa.String(length=24), nullable=False),
        sa.Column("owner_hash", sa.String(length=64), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("payload_hash", sa.String(length=64), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("failure_code", sa.String(length=64), nullable=True),
        sa.Column("lease_token", sa.String(length=26), nullable=True),
        sa.Column("lease_expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("attempt", sa.Integer(), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.CheckConstraint("attempt >= 0", name=op.f("ck_jobs_attempt_nonnegative")),
        sa.CheckConstraint(f"kind IN ({_JOB_KINDS})", name=op.f("ck_jobs_kind_allowed")),
        sa.CheckConstraint(f"status IN ({_JOB_STATUSES})", name=op.f("ck_jobs_status_allowed")),
        sa.CheckConstraint("version >= 0", name=op.f("ck_jobs_version_nonnegative")),
        sa.PrimaryKeyConstraint("job_id", name=op.f("pk_jobs")),
    )
    op.create_index("ix_jobs_owner_hash_created_at", "jobs", ["owner_hash", "created_at"])
    op.create_index("ix_jobs_status_created_at", "jobs", ["status", "created_at"])

    op.create_table(
        "outbox_events",
        sa.Column("event_id", sa.String(length=26), nullable=False),
        sa.Column("job_id", sa.String(length=26), nullable=False),
        sa.Column("topic", sa.String(length=96), nullable=False),
        sa.Column("event_version", sa.Integer(), nullable=False),
        sa.Column("payload", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("traceparent", sa.String(length=128), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(
            ["job_id"],
            ["jobs.job_id"],
            name=op.f("fk_outbox_events_job_id_jobs"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("event_id", name=op.f("pk_outbox_events")),
        sa.UniqueConstraint(
            "job_id",
            "topic",
            "event_version",
            name=op.f("uq_outbox_events_job_topic_version"),
        ),
    )
    op.create_index(
        "ix_outbox_events_unpublished",
        "outbox_events",
        ["created_at"],
        postgresql_where=sa.text("published_at IS NULL"),
    )

    op.create_table(
        "idempotency_keys",
        sa.Column("key_hash", sa.String(length=64), nullable=False),
        sa.Column("payload_hash", sa.String(length=64), nullable=False),
        sa.Column("job_id", sa.String(length=26), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["job_id"],
            ["jobs.job_id"],
            name=op.f("fk_idempotency_keys_job_id_jobs"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("key_hash", name=op.f("pk_idempotency_keys")),
        sa.UniqueConstraint("job_id", name=op.f("uq_idempotency_keys_job_id")),
    )
    op.create_index(
        "ix_idempotency_keys_created_at",
        "idempotency_keys",
        ["created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_idempotency_keys_created_at", table_name="idempotency_keys")
    op.drop_table("idempotency_keys")
    op.drop_index("ix_outbox_events_unpublished", table_name="outbox_events")
    op.drop_table("outbox_events")
    op.drop_index("ix_jobs_status_created_at", table_name="jobs")
    op.drop_index("ix_jobs_owner_hash_created_at", table_name="jobs")
    op.drop_table("jobs")
