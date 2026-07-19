from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0004_entitlements"
down_revision: str | None = "0003_leaderboard"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "store_transactions",
        sa.Column("event_id", sa.String(length=256), nullable=False),
        sa.Column("store", sa.String(length=24), nullable=False),
        sa.Column("transaction_id", sa.String(length=256), nullable=False),
        sa.Column("original_transaction_id", sa.String(length=256), nullable=False),
        sa.Column("product_id", sa.String(length=128), nullable=False),
        sa.Column("subject_hash", sa.String(length=64), nullable=False),
        sa.Column("event", sa.String(length=32), nullable=False),
        sa.Column("event_version", sa.Integer(), nullable=False),
        sa.Column("occurred_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("event_sha256", sa.String(length=64), nullable=False),
        sa.PrimaryKeyConstraint("event_id", name=op.f("pk_store_transactions")),
    )
    op.create_index(
        "ix_store_transactions_subject_occurred",
        "store_transactions",
        ["subject_hash", "occurred_at"],
    )
    op.create_table(
        "entitlements",
        sa.Column("subject_hash", sa.String(length=64), nullable=False),
        sa.Column("product_id", sa.String(length=128), nullable=False),
        sa.Column("store", sa.String(length=24), nullable=False),
        sa.Column("status", sa.String(length=24), nullable=False),
        sa.Column("original_transaction_id", sa.String(length=256), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_event_id", sa.String(length=256), nullable=False),
        sa.Column("last_event", sa.String(length=32), nullable=False),
        sa.Column("last_event_version", sa.Integer(), nullable=False),
        sa.Column("last_event_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(
            ["last_event_id"],
            ["store_transactions.event_id"],
            name=op.f("fk_entitlements_last_event_id_store_transactions"),
            ondelete="RESTRICT",
        ),
        sa.PrimaryKeyConstraint(
            "subject_hash",
            "product_id",
            name=op.f("pk_entitlements"),
        ),
        sa.UniqueConstraint(
            "last_event_id",
            name=op.f("uq_entitlements_last_event_id"),
        ),
    )


def downgrade() -> None:
    op.drop_table("entitlements")
    op.drop_index(
        "ix_store_transactions_subject_occurred",
        table_name="store_transactions",
    )
    op.drop_table("store_transactions")
