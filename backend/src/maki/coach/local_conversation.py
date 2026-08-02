from __future__ import annotations

import asyncio
import re
import time
import unicodedata
from collections import OrderedDict
from dataclasses import dataclass
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from collections.abc import Callable

_FINANCIAL_DISCLAIMER = (
    "\n\nBu yanıt eğitim amaçlıdır; önemli finans kararlarında koşullarını ayrıca değerlendir."
)

_INTENT_TERMS: dict[str, tuple[tuple[str, int], ...]] = {
    "fraud": (
        ("dolandirildim", 10),
        ("kartim calindi", 10),
        ("izinsiz islem", 10),
        ("sifrem calindi", 10),
    ),
    "debt": (
        ("kart borcu", 7),
        ("asgari odeme", 7),
        ("borc", 4),
        ("kredi", 4),
        ("faiz", 4),
    ),
    "emergency": (
        ("acil durum", 7),
        ("guvence", 4),
        ("acil fon", 7),
    ),
    "inflation": (
        ("kisisel enflasyon", 8),
        ("enflasyon", 5),
        ("tuik", 5),
        ("zam", 3),
        ("fiyat", 3),
    ),
    "receipt": (
        ("fis tara", 8),
        ("fis", 4),
        ("fatura", 4),
        ("ocr", 5),
    ),
    "report": (
        ("pdf", 6),
        ("rapor", 5),
        ("disa aktar", 5),
        ("indir", 2),
    ),
    "calendar": (
        ("yasayan orman", 8),
        ("takvim", 5),
        ("seri", 4),
        ("streak", 5),
        ("tohum", 4),
        ("orman", 4),
        ("gorev", 3),
    ),
    "goal": (
        ("hedef rotasi", 8),
        ("hedef haritasi", 8),
        ("hedef yolu", 8),
        ("hedef", 4),
        ("rota", 3),
        ("katki", 3),
    ),
    "savings": (
        ("para ayir", 7),
        ("birik", 5),
        ("tasarruf", 5),
    ),
    "budget": (
        ("butce", 5),
        ("harcama", 4),
        ("gider", 4),
        ("gelir", 4),
        ("toparla", 3),
    ),
    "help": (
        ("ne yapabilirsin", 9),
        ("neleri biliyorsun", 9),
        ("yardim", 6),
    ),
    "wellbeing": (
        ("nasilsin", 8),
        ("ne haber", 8),
        ("keyfin nasil", 8),
    ),
    "thanks": (
        ("tesekkur", 7),
        ("sag ol", 7),
        ("eyvallah", 6),
    ),
    "goodbye": (
        ("gorusuruz", 7),
        ("hosca kal", 7),
        ("kendine iyi bak", 7),
        ("bye", 6),
    ),
    "greeting": (
        ("gunaydin", 7),
        ("iyi aksamlar", 7),
        ("merhaba", 6),
        ("selam", 6),
        ("slm", 6),
    ),
}

_FINANCIAL_INTENTS = {
    "debt",
    "emergency",
    "inflation",
    "receipt",
    "report",
    "calendar",
    "goal",
    "savings",
    "budget",
}

_FOLLOW_UP_WORDS = {
    "hangisi",
    "nasil",
    "neden",
    "ne",
    "kadar",
    "peki",
    "devam",
    "olur",
    "evet",
    "tamam",
}
_MAX_FOLLOW_UP_WORDS = 7


class InvalidConversationConfigError(ValueError):
    pass


@dataclass(frozen=True, slots=True)
class _SessionMemory:
    topic: str
    updated_at: float


class LocalConversationEngine:
    def __init__(
        self,
        *,
        memory_ttl_seconds: float = 20 * 60,
        max_sessions: int = 256,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if memory_ttl_seconds <= 0 or max_sessions <= 0:
            raise InvalidConversationConfigError
        self._memory_ttl_seconds = memory_ttl_seconds
        self._max_sessions = max_sessions
        self._clock = clock
        self._sessions: OrderedDict[str, _SessionMemory] = OrderedDict()
        self._lock = asyncio.Lock()

    async def respond(self, question: str, session_id: str) -> str:
        normalized = _normalize(question)
        normalized_user_question = _normalize(_extract_user_question(question))
        now = self._clock()
        async with self._lock:
            self._evict_expired(now)
            previous = self._sessions.get(session_id)
            intent = _classify(normalized_user_question)
            if intent == "fallback":
                intent = _classify(normalized)
            if _is_follow_up(normalized_user_question) and previous is not None:
                intent = previous.topic
            response = _response(intent, normalized_user_question, previous)
            if intent in _FINANCIAL_INTENTS:
                self._sessions[session_id] = _SessionMemory(intent, now)
                self._sessions.move_to_end(session_id)
                while len(self._sessions) > self._max_sessions:
                    self._sessions.popitem(last=False)
        if intent in _FINANCIAL_INTENTS:
            return f"{response}{_FINANCIAL_DISCLAIMER}"
        return response

    def _evict_expired(self, now: float) -> None:
        expired = [
            session_id
            for session_id, memory in self._sessions.items()
            if now - memory.updated_at > self._memory_ttl_seconds
        ]
        for session_id in expired:
            self._sessions.pop(session_id, None)


def _response(  # noqa: C901, PLR0911, PLR0912
    intent: str,
    normalized: str,
    previous: _SessionMemory | None,
) -> str:
    if intent == "fraud":
        return (
            "Hemen bankanın resmî uygulamasından kartı geçici olarak kapat ve bankanın resmî "
            "destek hattını ara. Tanımadığın işlemler için itiraz kaydı oluştur; şifre, SMS kodu "
            "ve kart bilgini kimseyle paylaşma. Maki bu işlem için senden gizli bilgi istemez."
        )
    if intent == "greeting":
        return (
            "Merhaba! Ben Maki’nin cihazında çalışan yerel rehberiyim. Bütçe, borç, hedef, fiş, "
            "rapor, takvim ve Yaşayan Orman konusunda birlikte ilerleyebiliriz. Bugün neye bakalım?"
        )
    if intent == "wellbeing":
        return (
            "İyiyim, teşekkür ederim. Senin finans yükünü biraz hafifletmeye "
            "hazırım; bugün neyi çözmek istersin?"
        )
    if intent == "thanks":
        return "Rica ederim. Küçük ama sürdürülebilir bir sonraki adımı birlikte seçebiliriz."
    if intent == "goodbye":
        return "Görüşürüz! Maki ve ormanın burada; kaldığın yerden devam edebilirsin."
    if intent == "help":
        return (
            "Şunlarda yardımcı olabilirim: bütçe ve borç planı, birikim hedefi, fiş tarama, PDF "
            "raporları, kişisel enflasyon, takvim serisi ve Yaşayan Orman. Örneğin “Borçlarım için "
            "plan yapalım” diyebilirsin."
        )
    if intent == "debt":
        if previous is not None and previous.topic == "debt" and "hangisi" in normalized:
            return (
                "Toplam faiz maliyetini azaltmak önceliğinse en yüksek faizli borçtan başlayan Çığ "
                "yöntemi; hızlı moral kazanmak önceliğinse en küçük bakiyeden başlayan Kar Topu "
                "yöntemi daha uygundur. Asgari ödemeleri iki yöntemde de aksatma."
            )
        return (
            "1. Borçlarının kalan tutarını, faizini ve asgari ödemesini tek yerde topla. "
            "2. Asgarileri aksatmadan ek bütçeyi en yüksek faizli borca yönelt. "
            "3. Borç Kapatma Planı’nda Çığ ve Kar Topu seçeneklerini karşılaştır. Hangisini "
            "seçeceğini birlikte değerlendirebiliriz."
        )
    if intent == "emergency":
        return (
            "1. İlk hedefi bir haftalık zorunlu gider kadar belirle. 2. Birikimi günlük harcamadan "
            "ayrı ve erişilebilir bir yerde tut. 3. Düzen oturunca hedefi bir aylık zorunlu gidere "
            "doğru büyüt."
        )
    if intent == "inflation":
        return (
            "Kişisel enflasyon ekranı, senin harcama değişimini TÜİK’in resmî "
            "oranıyla aynı dönemde karşılaştırır. En az iki karşılaştırılabilir dönem "
            "oluştuğunda sonucu aç; yüksek farkın "
            "hangi gider gruplarından geldiğini incele ve yalnız o gruplar için sınır koy."
        )
    if intent == "receipt":
        return (
            "Fiş Tara ekranında fotoğrafı net ve tam kadraj çek. Maki işletme, tarih ve toplamı "
            "önerir; kaydetmeden önce tutarı doğrulamanı ister. Onayladığında fiş otomatik gider "
            "kaydına dönüşür."
        )
    if intent == "report":
        return (
            "Ayarlar > Raporlarım bölümünden günlük, haftalık veya aylık dönem seç. PDF cihazında "
            "oluşturulur; ardından indir veya paylaş düğmesini kullanabilirsin."
        )
    if intent == "calendar":
        return (
            "Takvimde her gün en az bir anlamlı finans davranışı tamamlamak seriyi "
            "korur. Gelir veya "
            "gider kaydı, fiş onayı, günlük kontrol ve hedef katkısı ormanı büyütür; görevlerden "
            "kazandığın tohumları Orman Mağazası’nda kullanabilirsin."
        )
    if intent == "goal":
        return (
            "Hedef Rotası kartına dokunup aktif hedefini seç. Yeni gelir veya gideri kaydederken "
            "“hedefi etkilesin” seçeneğini açarsan yalnız seçili hedef ilerler. “Hedef yolunu aç” "
            "düğmesi seni doğrudan o hedefin haritasına götürür."
        )
    if intent == "savings":
        if previous is not None and previous.topic == "savings" and "kadar" in normalized:
            return (
                "Tek bir kesin tutar yerine son dört haftanın zorunlu giderlerden sonraki netini "
                "kullan. Oynak haftaları hesaba katarak küçük bir alt sınır ve rahat bir üst sınır "
                "seç; katkıyı alt sınırdan başlatıp iki hafta sonra gözden geçir."
            )
        return (
            "1. Birikimi ay sonunda kalana bırakma; gelir geldiğinde küçük bir tutarı ayır. "
            "2. Hedef Rotası’nda amaç ve tarihi belirle. 3. Takvimde haftalık katkıyı izleyip "
            "sürdürülemezse tutarı küçült. Ne kadar ayırabileceğini birlikte hesaplayabiliriz."
        )
    if intent == "budget":
        return (
            "Son dört haftayı zorunlu, esnek ve ertelenebilir giderler olarak ayır. "
            "Tekrarlayan küçük bir gider seçip bu hafta yalnız onu azalt; farkı aktif "
            "hedefe yönlendir. Takvimde haftalık "
            "net değişimi kontrol ederek kararın etkisini ölç."
        )
    return (
        "Bunu doğru anlamak için bir konu seçelim: bütçe, borç, birikim hedefi, fiş, rapor, "
        "kişisel enflasyon veya Yaşayan Orman. Kısaca “Bütçemi toparlamak "
        "istiyorum” gibi yazabilirsin."
    )


def _classify(normalized: str) -> str:
    scores: dict[str, int] = {}
    for intent, terms in _INTENT_TERMS.items():
        score = sum(weight for term, weight in terms if _has_term(normalized, term))
        if score:
            scores[intent] = score
    if not scores:
        return "fallback"
    priority = {intent: index for index, intent in enumerate(_INTENT_TERMS)}
    return max(scores, key=lambda intent: (scores[intent], -priority[intent]))


def _is_follow_up(normalized: str) -> bool:
    tokens = set(normalized.split())
    return len(tokens) <= _MAX_FOLLOW_UP_WORDS and bool(tokens & _FOLLOW_UP_WORDS)


def _has_term(value: str, term: str) -> bool:
    return re.search(rf"(?<![a-z0-9]){re.escape(term)}", value) is not None


def _extract_user_question(value: str) -> str:
    marker = "kullanıcının sorusu:"
    marker_index = value.casefold().rfind(marker)
    if marker_index < 0:
        return value
    return value[marker_index + len(marker) :].strip()


def _normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    without_marks = "".join(
        character for character in decomposed if not unicodedata.combining(character)
    )
    return " ".join(re.findall(r"[a-z0-9]+", without_marks))
