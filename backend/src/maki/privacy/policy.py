from dataclasses import dataclass

from maki.privacy.models import PrivacyViolation

FORBIDDEN_KEYS = frozenset(
    {
        "amount",
        "balance",
        "card_number",
        "chat_history",
        "debt_balance",
        "exact_date",
        "history",
        "iban",
        "merchant",
        "merchant_name",
        "notes",
        "store_name",
        "transaction_date",
    }
)

_DEPTH_KEY = "$derinlik"


@dataclass(frozen=True, slots=True)
class PrivacyPolicy:
    forbidden_keys: frozenset[str] = FORBIDDEN_KEYS
    max_depth: int = 20

    def __post_init__(self) -> None:
        if self.max_depth < 1:
            msg = "Gizlilik tarama derinliği en az bir olmalıdır."
            raise ValueError(msg)

    def inspect_json(self, value: object) -> tuple[PrivacyViolation, ...]:
        violations: list[PrivacyViolation] = []
        self._inspect(value=value, path="$", depth=0, violations=violations)
        return tuple(sorted(violations, key=lambda item: item.path))

    def _inspect(
        self,
        *,
        value: object,
        path: str,
        depth: int,
        violations: list[PrivacyViolation],
    ) -> None:
        if depth > self.max_depth:
            violations.append(PrivacyViolation(path=path, key=_DEPTH_KEY))
            return
        if isinstance(value, dict):
            self._inspect_mapping(value=value, path=path, depth=depth, violations=violations)
            return
        if isinstance(value, list):
            for index, item in enumerate(value):
                self._inspect(
                    value=item,
                    path=f"{path}[{index}]",
                    depth=depth + 1,
                    violations=violations,
                )

    def _inspect_mapping(
        self,
        *,
        value: dict[object, object],
        path: str,
        depth: int,
        violations: list[PrivacyViolation],
    ) -> None:
        for key, item in value.items():
            key_text = str(key)
            item_path = f"{path}.{key_text}"
            if key_text.casefold() in self.forbidden_keys:
                violations.append(PrivacyViolation(path=item_path, key=key_text))
            self._inspect(
                value=item,
                path=item_path,
                depth=depth + 1,
                violations=violations,
            )
