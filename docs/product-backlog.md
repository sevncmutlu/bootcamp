# Product Backlog — Maki Finans Koçu

**Takım:** Takım 120

**Product Owner:** Emir Hüseyin İnci

**Scrum Master:** Sevinç Mutlu
**Son güncelleme:** 1 Ağustos 2026

## Durum sözlüğü

- **Tamamlandı:** Kod, temel test ve kullanıcı akışı mevcut.
- **Dış yapılandırma bekliyor:** Kod hazır; canlı hesap, imza veya servis değeri gerekir.
- **Sonraki sürüm:** Teslim ZIP'inin kapsamına girmeyen geliştirme adayı.

Story point; saat değil, efor + belirsizlik + karmaşıklık için göreli Fibonacci
ölçeğidir. Tarihsel sprint kayıtları Sprint 1–3 klasörlerinde korunur.

## Epic özeti

| Epic | Kapsam | Durum |
|---|---|---|
| E0 | Ürün vizyonu, hedef kitle ve mimari | Tamamlandı |
| E1 | Flutter temel, tema, onboarding ve yerel profil | Tamamlandı |
| E2 | Gelir/gider ve finans takvimi | Tamamlandı |
| E3 | PaddleOCR fiş akışı | Tamamlandı |
| E4 | Maki Koç, yerel rehber ve Gemini bağlantısı | Tamamlandı |
| E5 | Kişisel enflasyon, tahmin ve paylaşılabilir kart | Tamamlandı |
| E6 | Yaşayan Finans Ormanı ve 325 görev | Tamamlandı |
| E7 | Akıllı bildirim zamanlaması | Tamamlandı |
| E8 | Borç stratejileri ve premium sınırı | Dış yapılandırma bekliyor |
| E9 | Gizlilik, yerel veri ve kimlik sınırı | Tamamlandı |
| E10 | Gözlemlenebilirlik, CI ve güvenlik kapıları | Tamamlandı |
| E11 | Android/iOS/web responsive ürün deneyimi | Tamamlandı |
| E12 | Hedef rotaları ve cihaz içi raporlar | Tamamlandı |
| E13 | Production kapanışı: kuruş tabanlı DB, gerçek bildirim, enflasyon/tahmin ve fail-closed release | Tamamlandı |

## Sprint 1 — Ürün ve mimari

| ID | User story / çıktı | SP | Durum |
|---|---|---:|---|
| S1-01 | Problem, hedef kitle ve değer önermesi | 13 | Tamamlandı |
| S1-02 | Maki kimliği ve orman metaforu | 13 | Tamamlandı |
| S1-03 | Flutter, FastAPI, Drift ve model yığını kararı | 21 | Tamamlandı |
| S1-04 | Cihaz öncelikli gizlilik mimarisi | 21 | Tamamlandı |
| S1-05 | Üç sprintlik kapsam, risk ve DoD | 13 | Tamamlandı |
| S1-06 | Kategori taksonomisi ve ilk kullanıcı akışları | 8 | Tamamlandı |
| S1-07 | Scrum kayıtları ve sunum materyalleri | 11 | Tamamlandı |
|  | **Toplam** | **100** |  |

## Sprint 2 — Güvenli çekirdek ve mobil teslim

| ID | User story / çıktı | SP | Durum |
|---|---|---:|---|
| S2-01 | Flutter mimari sınırları ve Türkçe tasarım sistemi | 8 | Tamamlandı |
| S2-02 | Drift/SQLite3MC yerel veri ve güvenli cihaz depolaması | 8 | Tamamlandı |
| S2-03 | Gelir/gider, kategoriler ve form doğrulaması | 8 | Tamamlandı |
| S2-04 | PaddleOCR iş kuyruğu ve fiş sonucu onayı | 8 | Tamamlandı |
| S2-05 | Maki Koç, RAG/sağlayıcı sınırı ve kaynak kartları | 8 | Tamamlandı |
| S2-06 | Deterministik para, oran ve kişisel enflasyon çekirdeği | 13 | Tamamlandı |
| S2-07 | Tahmin, geriye dönük sınama ve model seçimi | 8 | Tamamlandı |
| S2-08 | Borç kapatma motoru ve tutarlı silme akışı | 8 | Tamamlandı |
| S2-09 | İlk Maki Ormanı, maskot ve uyarlanabilir ekranlar | 8 | Tamamlandı |
| S2-10 | Pydantic v2 API, idempotency ve hata sözleşmesi | 8 | Tamamlandı |
| S2-11 | OpenTelemetry, kişisel veri temizleme ve alarm kuralları | 8 | Tamamlandı |
| S2-12 | CI, SBOM, güvenlik ve fiziksel Android kanıtı | 5 | Tamamlandı |
|  | **Toplam** | **100** |  |

## Sprint 3 — Kişiselleştirme ve Yaşayan Finans Ormanı

| ID | User story / kabul özeti | SP | Durum |
|---|---|---:|---|
| S3-01 | Android, iOS ve web için responsive gezinme | 13 | Tamamlandı |
| S3-02 | Dört amacın ana ekran, görev, öneri ve analizi değiştirmesi | 13 | Tamamlandı |
| S3-03 | Haftalık özet ve tam ekran finans takvimi | 8 | Tamamlandı |
| S3-04 | 325 benzersiz görev ve güne/rotaya bağlı deterministik seçim | 13 | Tamamlandı |
| S3-05 | Seri, XP, tohum cüzdanı, mağaza ve koruma yaprağı | 13 | Tamamlandı |
| S3-06 | Yerel bitki parselleri ve tam ekran orman deneyimi | 8 | Tamamlandı |
| S3-07 | Hedef oluşturma, 30 duraklı harita ve kilometre taşları | 13 | Tamamlandı |
| S3-08 | Gelir/gideri açık seçimle hedefe bağlama ve geri alma | 8 | Tamamlandı |
| S3-09 | Günlük/haftalık/aylık cihaz içi PDF rapor merkezi | 8 | Tamamlandı |
| S3-10 | Fiş toplam çıkarımı ve doğrudan gider taslağı | 8 | Tamamlandı |
| S3-11 | Kişisel enflasyon Maki kartı, indirme ve paylaşma | 5 | Tamamlandı |
| S3-12 | Sürüklenebilir, kenara yaslanan ve konumunu hatırlayan Maki | 5 | Tamamlandı |
| S3-13 | Bildirim ekranındaki debug yüzeyini kaldırma ve yaş profili | 5 | Tamamlandı |
| S3-14 | Yükleme, yönlendirme, ekran dönüşü ve düşük cihaz kararlılığı | 8 | Tamamlandı |
| S3-15 | Tema renginin bütün ürün yüzeylerine uygulanması | 5 | Tamamlandı |
| S3-16 | Borç için hazır/özel stratejiler ve sade Türkçe | 8 | Tamamlandı |
| S3-17 | Yerel rehber + isteğe bağlı güvenli Gemini anahtarı | 5 | Tamamlandı |
| S3-18 | Flutter analiz, 178 test, web preview release ve Android cihaz doğrulaması | 8 | Tamamlandı |
| S3-19 | Android PDF için sistem “Farklı kaydet” akışı ve iptal durumunun doğru işlenmesi | 3 | Tamamlandı |
| S3-20 | Int64 kuruş migration'ı, gerçek OS bildirimi, fiyat sepeti/Laspeyres, yerel tahmin, mega-widget ayrıştırması ve fail-closed release | 13 | Tamamlandı |

## Tamamlanan kabul ölçütleri

### Finans ve hedefler

- Kullanıcı gelir ve gideri gün/tür/kategori bazında kaydedebilir.
- Takvimde seçilen günün gelir, gider, net ve işlem sayısı gösterilir.
- Hedef kartının ikinci sayfası biriken, kalan, yüzde ve hedef tarihini gösterir.
- İşlemler varsayılan olarak hedefi etkilemez; kullanıcı açıkça seçerse etkiler.
- Bağlı gider, hedefte mevcut birikimden büyükse kayıt öncesinde engellenir.
- Aynı hedefte aynı kilometre taşı yalnız bir kez ödül verir.

### Orman ve görevler

- Katalog tam 325 benzersiz görev içerir.
- Her gün üç rota görevi ve bir bonus görev deterministik biçimde seçilir.
- Seçilen amaç görev ailelerini, ana kartı ve Maki önerisini değiştirir.
- Tohum kazanımı ve mağaza harcaması cihazdaki deftere kaydedilir.
- Büyüme aşaması ve görsel yol gerçek finans etkinliklerinden hesaplanır.

### Gizlilik ve güvenlik

- Finans kayıtları ve rapor üretimi cihaz içinde kalır.
- Hata raporlarında e-posta, IBAN, kart ve telefon desenleri temizlenir.
- Geliştirme oturumu ile üretim kimliği birbirinden ayrılır.
- Backend yalnız EdDSA, ES256 veya RS256 kısa ömürlü belirteç kabul eder.
- GitHub teslim paketi `.env`, anahtar, yerel DB, log veya kullanıcı verisi içermez.

## Dış yapılandırma bekleyen işler

| ID | İş | Tamamlanma koşulu |
|---|---|---|
| RC-01 | Android production signing | Release keystore ve Play Console erişimi |
| RC-02 | iOS signing ve cihaz testi | macOS, Apple certificate ve provisioning profile |
| RC-03 | Canlı OIDC | Issuer, client, audience ve redirect URI |
| RC-04 | Canlı mağaza satın alması | Store ürünleri ve backend doğrulama hesapları |
| RC-05 | Canlı yasal sayfalar | Privacy ve Terms HTTPS URL'leri |
| RC-06 | Canlı servis izleme | Sentry DSN ve OTLP hedefi |

Bu maddeler kod eksikliği değil, proje dışında yönetilen canlı yayın kimlikleri ve
hesaplarıdır. Değerler kaynak koda eklenmez.

## Sonraki sürüm adayları

| ID | Fikir | Öncelik |
|---|---|---|
| N-01 | Kullanıcı kontrollü, uçtan uca şifreli Drive/iCloud yedeği | Yüksek |
| N-02 | Erişilebilirlik için ekran okuyucu senaryo paketi | Yüksek |
| N-03 | OCR veri kümesinde mağaza ve fiş tipi bazlı kalite panosu | Orta |
| N-04 | Tablet için iki panelli hedef/orman görünümü | Orta |
| N-05 | Tamamen çevrimdışı cihaz içi OCR araştırması | Düşük |

## Definition of Done

Bir backlog kalemi ancak kullanıcı akışı mevcutsa, hata/boş/yükleniyor durumu
tanımlıysa, gizlilik sınırı korunuyorsa ve uygun analiz/test kapısı geçiyorsa
“Tamamlandı” olarak işaretlenir. Dış hizmet gerektiren özellikler canlı hesap olmadan
“üretimde çalışıyor” olarak sunulmaz.
