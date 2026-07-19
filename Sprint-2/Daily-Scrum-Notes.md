# 🗓️ Sprint 2 Günlük İlerleme Notları

## 6–8 Temmuz — Temel

- Flutter uygulama sınırları, tema ve yerel veri katmanı kuruldu.
- Backend servis katmanları ve Pydantic v2 sözleşmeleri ayrıştırıldı.
- Para, oran ve yuvarlama kuralları finans çekirdeğine taşındı.

## 9–11 Temmuz — Ana Akışlar

- Harcama, OCR ve MakiKoç uçları mobil akışlarla eşleştirildi.
- Resmî veri kaynakları ve kaynak kartları eklendi.
- İş kuyruğunda idempotency, sonuç süresi ve hata sözleşmeleri tamamlandı.

## 12–14 Temmuz — Finansal Modelleme

- Kişisel enflasyon ve borç kapatma motoru test edildi.
- Prophet için basit taban, geriye dönük sınama ve model seçimi eklendi.
- LightGBM model bildirimi ve cihaz tarafı doğrulama sınırı oluşturuldu.

## 15–17 Temmuz — İşletim ve Güvenlik

- OpenTelemetry; FastAPI, HTTP, PostgreSQL, Redis ve işçilere bağlandı.
- Hassas veri temizleme, telemetry gizlilik testi ve alarm kuralları eklendi.
- CI; lint, tip, test, güvenlik taraması, SBOM ve yük testleriyle genişletildi.

## 18–19 Temmuz — Mobil Sonlandırma

- Tüm kullanıcı metinleri Türkçeleştirildi.
- Açılış animasyonu, maskot ve Maki Ormanı tamamlandı.
- Borç silme durumu ve dar ekran taşmaları giderildi.
- Kalite kapıları çalıştırıldı; APK fiziksel Android cihazda doğrulandı.

## Engeller

- Yerel ortamda Docker bulunmadığı için 9 konteyner entegrasyon testi atlandı.
- Üretim mağaza imzası ve canlı sağlayıcı bilgileri Sprint 3/MVP kapsamına bırakıldı.
