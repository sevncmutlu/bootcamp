# 🔍 Sprint 2 Review

**Tarih:** 19 Temmuz · **Durum:** ✅ Kabul edildi

**Katılımcılar:** Emir Hüseyin İnci, Sevinç Mutlu, Shajar Ahmad Ahanger (Developer)

## Sprint Hedefi

Ürünü temel prototip düzeyinden; backend, finans çekirdeği, gözlemlenebilirlik ve mobil
teslim zinciri birlikte çalışan bir Sprint 2 sürümüne taşımak.

## Tamamlanan Değer

- Harcama ekleme ve yerel saklama
- Güvenli fiş OCR iş akışı
- Türkçe, kaynaklı MakiKoç deneyimi
- Kişisel enflasyon ve olasılıksal harcama tahmini
- Deterministik borç kapatma planı
- Gerçek veriye bağlı Maki Ormanı ve maskot animasyonları
- Pydantic v2 tabanlı sürümlü API sözleşmeleri
- OpenTelemetry izleri, güvenli loglar ve operasyon alarmları
- Otomatik kalite, güvenlik ve teslim kapıları

## Doğrulama Kanıtı

| Kapı | Sonuç |
|------|-------|
| Ruff ve mypy | ✅ |
| Backend testleri | ✅ 193 başarılı |
| Backend test kapsamı | ✅ %73,29 |
| Finans çekirdeği | ✅ 45 başarılı |
| Flutter analizi | ✅ |
| Flutter testleri | ✅ 31 başarılı |
| Android APK | ✅ Derlendi ve fiziksel cihazda çalıştı |
| APK parmak izi | ✅ [Kayıtlı](../docs/evidence/sprint-2-apk.md) |

Docker gerektiren 9 entegrasyon testi yerelde atlanmış, CI ortamında çalışacak şekilde
teslim zincirine eklenmiştir.

## OpenTelemetry İncelemesi

- İz bağlamı API'den iş kuyruğuna ve işçiye taşınır.
- HTTP, PostgreSQL ve Redis işlemleri otomatik ölçümlenir.
- İstek gövdesi, finansal içerik ve erişim belirteçleri kaydedilmez.
- Collector bellek sınırı ve toplu gönderimle yapılandırılmıştır.
- Hata oranı, gecikme ve kuyruk sağlığı için alarm kuralları sürüm kontrolündedir.

## Karar

100 / 100 SP tamamlandı. Sprint 2 fiziksel cihaz sürümü kabul edildi. Üretim imzası,
canlı mağaza kimlikleri ve canlı sağlayıcı anahtarları Sprint 3/MVP teslim kapısına
devredildi.
