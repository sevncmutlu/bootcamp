# 📋 Sprint 2 Backlog

**Sprint:** 6 – 19 Temmuz · **Kapasite:** 100 SP · **Durum:** ✅ Tamamlandı

## Sprint İşleri

| ID | Kullanıcı değeri / teknik iş | SP | Kabul ölçütü | Durum |
|----|------------------------------|----|--------------|-------|
| S2-01 | Mobil mimari, tasarım sistemi ve Türkçe arayüz | 8 | Ana akışlar ortak tema, bileşen ve Türkçe metin kullanır. | ✅ |
| S2-02 | Şifreli yerel veri ve güvenli oturum yönetimi | 8 | Finans verisi cihazda, erişim belirteci güvenli depoda tutulur. | ✅ |
| S2-03 | Harcama yönetimi, kategoriler ve alan doğrulama | 8 | Ekleme, listeleme, silme ve doğrulama tutarlı çalışır. | ✅ |
| S2-04 | Güvenli fiş OCR iş akışı | 8 | Dosya sınırları doğrulanır; geçici sonuçlar süre sonunda silinir. | ✅ |
| S2-05 | Türkçe MakiKoç, RAG ve resmî kaynak kartları | 8 | Yanıtlar Türkçe, kaynaklı ve kişisel veri sızıntısına kapalıdır. | ✅ |
| S2-06 | Para güvenli finans çekirdeği ve kişisel enflasyon | 13 | Yuvarlama, para birimi ve enflasyon değişmezleri testlidir. | ✅ |
| S2-07 | Tahmin, geriye dönük sınama ve model seçimi | 8 | Prophet yalnızca basit tabanı geçtiğinde seçilir; belirsizlik sunulur. | ✅ |
| S2-08 | Borç kapatma motoru ve tutarlı silme akışı | 8 | Strateji deterministiktir; silinen borç ekrandan hemen kalkar. | ✅ |
| S2-09 | Maki Ormanı, maskot ve uyarlanabilir ekranlar | 8 | İlerleme gerçek veriye bağlıdır; dar ekranda taşma oluşmaz. | ✅ |
| S2-10 | Pydantic v2 API sözleşmeleri ve güvenilir iş kuyruğu | 8 | Sürümlü şemalar, idempotency ve hata sözleşmeleri testlidir. | ✅ |
| S2-11 | OpenTelemetry, kişisel veri temizleme ve alarmlar | 8 | İzler uçtan uca taşınır; içerik ve kişisel veri telemetry'ye girmez. | ✅ |
| S2-12 | CI kalite kapıları, SBOM ve telefon APK kaydı | 5 | Test, lint, güvenlik, SBOM ve APK kanıtı teslim zincirindedir. | ✅ |
|  | **Toplam** | **100** |  | **✅** |

## OpenTelemetry Kabul Kriterleri

- FastAPI, HTTP istemcisi, PostgreSQL, Redis ve arka plan işçileri aynı iz bağlamını
  sürdürebilir.
- OTLP çıkışı ortam değişkeniyle yapılandırılır; kod içine adres veya anahtar gömülmez.
- İstek gövdesi, finansal tutar, fiş içeriği ve erişim belirteci iz özelliği olamaz.
- Hassas anahtarlar yapılandırılmış log katmanında temizlenir.
- Collector bellek sınırlama, toplu gönderim ve sağlık denetimi işlemcileri kullanır.
- Hata oranı, gecikme, kuyruk yaşı ve iş başarısızlığı için alarm kuralları bulunur.
- Telemetry gizlilik sözleşmesi otomatik kabul testiyle korunur.

## Kapsam Dışı

- Üretim mağaza imzası ve gerçek mağaza kimlikleri
- Canlı servis anahtarları
- iOS dağıtım profilleri
- Uzun dönem üretim gösterge panelleri

Bu işler Sprint 3/MVP teslim kapısında değerlendirilecektir.
