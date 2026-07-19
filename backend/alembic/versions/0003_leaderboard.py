from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0003_leaderboard"
down_revision: str | None = "0002_official_data"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "leaderboard_contributions",
        sa.Column("cohort_hash", sa.String(length=64), nullable=False),
        sa.Column("subject_hash", sa.String(length=64), nullable=False),
        sa.Column("contribution_day", sa.Date(), nullable=False),
        sa.Column("score_basis_points", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.CheckConstraint(
            "score_basis_points BETWEEN 0 AND 10000",
            name=op.f("ck_leaderboard_contributions_score_basis_points_range"),
        ),
        sa.PrimaryKeyConstraint(
            "cohort_hash",
            "subject_hash",
            "contribution_day",
            name=op.f("pk_leaderboard_contributions"),
        ),
    )
    op.create_index(
        "ix_leaderboard_cohort_expiry_score",
        "leaderboard_contributions",
        ["cohort_hash", "expires_at", "score_basis_points"],
    )


def downgrade() -> None:
    op.drop_index(
        "ix_leaderboard_cohort_expiry_score",
        table_name="leaderboard_contributions",
    )
    op.drop_table("leaderboard_contributions")
