# 🗓️ Sprint 2 Planlama

**Tarih:** 6 Temmuz · **Kapasite:** 100 SP

**Katılımcılar:** Emir Hüseyin İnci, Sevinç Mutlu, Shajar Ahmad Ahanger (Developer)

## Hedef

Sprint 1'deki ürün kararlarını; fiziksel Android cihazda çalışan, backend ile uyumlu,
ölçülebilir ve güvenli bir Sprint 2 sürümüne dönüştürmek.

## Öncelik Sırası

1. Veri güvenliği ve finansal doğruluk
2. Mobil ile API sözleşmesinin uyumu
3. Harcama, OCR, koçluk ve borç akışlarının tamamlanması
4. OpenTelemetry ve güvenli işletim
5. Arayüz taşmaları, Türkçe metinler ve görsel bütünlük
6. Otomatik doğrulama ve telefon APK kaydı

## Teslim Stratejisi

- Para ve oran hesapları ortak finans çekirdeğinde tutulur.
- Mobil uygulama yalnızca sürümlü API sözleşmelerine bağlanır.
- Tahmin modeli basit tabana karşı geriye dönük sınamayla seçilir.
- Kişisel veri mobil cihazdan gereksiz yere çıkmaz.
- İz, metrik ve loglar içerik değil teknik durum taşır.
- Her katman bağımsız test edilir; son kapı fiziksel cihaz doğrulamasıdır.

## Riskler

| Risk | Önlem |
|------|-------|
| OCR içeriğinin kalıcı tutulması | Süreli geçici depolama ve otomatik silme |
| Prophet'in zayıf veride yanıltması | Basit taban, geriye dönük sınama ve güven aralığı |
| Para yuvarlama hataları | Tam sayı alt birim ve özellik tabanlı testler |
| Mobil ekran taşmaları | Uyarlanabilir düzen ve dar ekran widget testleri |
| Telemetry'de kişisel veri | İzinli özellik listesi, temizleme ve kabul testi |
| Backend kesintisinde veri kaybı | Yerel öncelikli akış ve açık hata durumları |

## Tamamlanma Tanımı

Kod, test ve belge birlikte teslim edilir; statik denetimler temizdir; seçilmiş
ekranlar ve telefon APK parmak izi depoda kayıtlıdır.
