from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0002_official_data"
down_revision: str | None = "0001_jobs_outbox"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "source_snapshots",
        sa.Column("snapshot_id", sa.String(length=26), nullable=False),
        sa.Column("source_name", sa.String(length=32), nullable=False),
        sa.Column("source_version", sa.String(length=128), nullable=False),
        sa.Column("schema_version", sa.Integer(), nullable=False),
        sa.Column("content_sha256", sa.String(length=64), nullable=False),
        sa.Column("etag", sa.String(length=512), nullable=True),
        sa.Column("state", sa.String(length=16), nullable=False),
        sa.Column("point_count", sa.Integer(), nullable=False),
        sa.Column("staged_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint(
            "state IN ('staged','published')",
            name=op.f("ck_source_snapshots_state_allowed"),
        ),
        sa.CheckConstraint(
            "point_count > 0",
            name=op.f("ck_source_snapshots_point_count_positive"),
        ),
        sa.PrimaryKeyConstraint("snapshot_id", name=op.f("pk_source_snapshots")),
        sa.UniqueConstraint(
            "source_name",
            "source_version",
            "content_sha256",
            name="uq_source_snapshots_identity",
        ),
    )
    op.create_index(
        "ix_source_snapshots_source_published",
        "source_snapshots",
        ["source_name", "published_at"],
    )

    op.create_table(
        "series_points",
        sa.Column("snapshot_id", sa.String(length=26), nullable=False),
        sa.Column("series_id", sa.String(length=64), nullable=False),
        sa.Column("period", sa.Date(), nullable=False),
        sa.Column("value", sa.Numeric(precision=38, scale=18), nullable=False),
        sa.Column("unit", sa.String(length=32), nullable=False),
        sa.Column("frequency", sa.String(length=16), nullable=False),
        sa.Column("release_date", sa.Date(), nullable=False),
        sa.Column("source_url", sa.String(length=2048), nullable=False),
        sa.Column("retrieved_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "frequency IN ('monthly','daily')",
            name=op.f("ck_series_points_frequency_allowed"),
        ),
        sa.ForeignKeyConstraint(
            ["snapshot_id"],
            ["source_snapshots.snapshot_id"],
            name=op.f("fk_series_points_snapshot_id_source_snapshots"),
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint(
            "snapshot_id",
            "series_id",
            "period",
            name=op.f("pk_series_points"),
        ),
    )

    op.create_table(
        "source_publications",
        sa.Column("source_name", sa.String(length=32), nullable=False),
        sa.Column("snapshot_id", sa.String(length=26), nullable=False),
        sa.Column("published_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["snapshot_id"],
            ["source_snapshots.snapshot_id"],
            name=op.f("fk_source_publications_snapshot_id_source_snapshots"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint(
            "source_name",
            name=op.f("pk_source_publications"),
        ),
        sa.UniqueConstraint(
            "snapshot_id",
            name=op.f("uq_source_publications_snapshot_id"),
        ),
    )


def downgrade() -> None:
    op.drop_table("source_publications")
    op.drop_table("series_points")
    op.drop_index(
        "ix_source_snapshots_source_published",
        table_name="source_snapshots",
    )
    op.drop_table("source_snapshots")
