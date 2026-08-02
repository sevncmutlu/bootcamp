from __future__ import annotations

import unicodedata

from maki.coach.models import CoachAnswer, CoachQuery, CoachSafety
from maki.privacy.scrubber import TextScrubber

_DISCLAIMER = (
    "\n\nBu yanıt eğitim amaçlıdır; önemli finans kararlarında koşullarını ayrıca değerlendir."
)


class LocalCoachService:
    def __init__(self, scrubber: TextScrubber | None = None) -> None:
        self._scrubber = scrubber or TextScrubber()

    async def answer(self, query: CoachQuery) -> CoachAnswer:
        question = self._scrubber.scrub(query.question).text
        answer = _guidance(question)
        return CoachAnswer(
            answer=f"{answer}{_DISCLAIMER}",
            safety=CoachSafety.LOCAL_GUIDANCE,
            sources=(),
        )


def _guidance(question: str) -> str:
    normalized = _normalize(question)
    if _contains(normalized, "borc", "kredi", "faiz", "kart borcu"):
        return (
            "Önce tüm borçlarının kalan tutarını, faizini ve asgari ödemesini tek yerde gör. "
            "Asgari ödemeleri aksatmadan ek parayı faiz oranı en yüksek borca yöneltmek "
            "toplam maliyeti azaltabilir. Motivasyon için küçük borcu önce kapatma yolunu da "
            "Borç Kapatma Planı ekranında karşılaştırabilirsin."
        )
    if _contains(normalized, "birik", "tasarruf", "hedef", "para ayir"):
        return (
            "Birikimi ay sonunda kalana bırakma: gelir geldiği gün sürdürebileceğin küçük bir "
            "tutarı ayrı hesaba aktar. Önce bir haftalık temel gider hedefle; düzen oturunca "
            "hedefi bir aya doğru büyüt. Takvimde haftalık katkını işaretlemek ilerlemeyi "
            "görünür kılar."
        )
    if _contains(normalized, "acil", "guvence", "fon"):
        return (
            "Acil durum birikimini erişilebilir ve düşük riskli ayrı bir yerde tut. İlk hedefi "
            "bir haftalık zorunlu gider olarak seç; sonra bir aylık gider seviyesine adım adım "
            "çıkar. "
            "Bu para günlük harcamalar veya planlı alışveriş için kullanılmamalı."
        )
    if _contains(normalized, "butce", "harcama", "gider", "gelir", "toparla"):
        return (
            "Son dört haftanın gelir ve giderlerini üç gruba ayır: zorunlu, esnek ve "
            "ertelenebilir. Önce tekrar eden küçük giderleri bul, yalnızca bir tanesini azalt "
            "ve farkı hedef hesabına "
            "aktar. Maki takviminde haftalık net tutarı izleyerek kararının etkisini görebilirsin."
        )
    if _contains(normalized, "enflasyon", "zam", "fiyat"):
        return (
            "Fiyat artışını tek bir aya bakarak yorumlama; birkaç aylık temel gider ortalamanı "
            "karşılaştır. "
            "Sık aldığın ürünlerde miktarı da not etmek gerçek değişimi görmeyi kolaylaştırır. "
            "Bütçende önce zorunlu gider payını güncelle, sonra hedef katkını yeniden ayarla."
        )
    return (
        "Bunu küçük ve ölçülebilir bir adıma çevirelim: bugün yalnızca son yedi günün gelir ve "
        "giderlerini tamamla, ardından haftalık net tutarına bak. Sonuca göre tek bir hedef seç; "
        "Maki aynı anda her şeyi değiştirmek yerine sürdürülebilir bir sonraki adımı önerecek."
    )


def _normalize(value: str) -> str:
    decomposed = unicodedata.normalize("NFKD", value.casefold())
    return "".join(character for character in decomposed if not unicodedata.combining(character))


def _contains(value: str, *needles: str) -> bool:
    return any(needle in value for needle in needles)
