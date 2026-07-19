class IdempotencyConflictError(Exception):
    def __init__(self) -> None:
        super().__init__("Tekrarlama anahtarı farklı bir istek için kullanılmış.")


class UnsafeJobPayloadError(Exception):
    def __init__(self) -> None:
        super().__init__("İş içeriği gizlilik politikasına uymuyor.")


class JobNotFoundError(Exception):
    def __init__(self) -> None:
        super().__init__("İş bulunamadı.")
