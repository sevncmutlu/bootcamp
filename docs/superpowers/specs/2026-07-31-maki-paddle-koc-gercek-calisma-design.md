# Maki PaddleOCR, Koç ve Gerçek Çalışma Tasarımı

Tarih: 31 Temmuz 2026

## 1. Amaç

Maki'nin fiş tarama ve koç ekranlarını yalnızca arayüz gösteren prototipler olmaktan çıkarıp yerel geliştirmede gerçekten çalışır hâle getirmek; bunu yaparken üretim güvenlik sınırlarını, fiş gizliliğini ve mevcut kuyruk mimarisini korumak.

Bu çalışma ayrıca daha önce onaylanan borç planları, kullanıcı tanımlı planlar, duyarlı finans yerleşimi ve Sena'nın önerdiği sade müşteri dili kapsamını tamamlar.

## 2. Seçilen yaklaşım

Yerel geliştirmede Docker gerektirmeyen bir çalışma yolu, üretimde ise mevcut PostgreSQL + Redis + ayrı worker mimarisi kullanılacaktır.

- `local` modunda aynı HTTP iş sözleşmesi korunur; işler süreç içindeki kısa ömürlü depoda tutulur ve OCR/koç işlemi arka planda yürür.
- `queue` modunda mevcut kalıcı iş kaydı, Redis kuyruğu ve ayrı worker süreci değişmeden kalır.
- Mod seçimi yalnızca backend ayarıdır. Mobil istemci aynı `202 Accepted -> job poll -> result` akışını kullanır.
- Üretim ortamında `local` mod açılamaz.

## 3. PaddleOCR kurulumu

PaddleOCR ücretli servis veya API anahtarı kullanmaz. Kurulum komutu:

1. Backend'in sürümlenmiş OCR bağımlılıklarını sanal ortama kurar.
2. PaddleOCR'ın resmî model indirme mekanizmasıyla Türkçe/Latin tanıma ve metin tespit modellerini proje içindeki göz ardı edilen `.local/paddle-models` dizinine hazırlar.
3. Model dizinlerini ve beklenen dosyaları doğrular.
4. Model sürümü ile kurulum zamanını bir manifestte saklar.
5. Aynı sürüm zaten hazırsa tekrar indirmez.
6. Sentetik Türkçe fiş görseliyle gerçek çıkarım duman testi çalıştırır.

Model dosyaları git'e eklenmez. Fiş görseli OCR tamamlandığında bellekten atılır; yerel mod diske ham fiş yazmaz.

## 4. Yerel fiş iş akışı

`MAKI_EXECUTION_MODE=local` ve model dizinleri hazır olduğunda backend:

- kısa ömürlü fiş baytlarını kullanıcı ve tek kullanımlık nesne kimliğiyle bellekte tutar;
- işi kabul edip hemen iş kimliği döndürür;
- `asyncio` görevi içinde dosya güvenlik kontrolü, PaddleOCR ve fiş ayrıştırıcıyı çalıştırır;
- sonucu mevcut iş sorgulama cevabıyla döndürür;
- başarı veya hata sonrasında ham görseli siler;
- zaman aşımına uğrayan işler ve sonuçları otomatik temizler.

Sıfır bayt, 8 MiB üzeri dosya, yanlış MIME/imza, bozuk görsel ve model hazır değil durumları kullanıcıya eyleme dönük Türkçe hata verir.

## 5. Maki Koç

Koç iki kademeli çalışır:

1. **Yerel rehber:** API anahtarı olmadan bütçe, birikim, borç, acil durum fonu ve harcama alışkanlığı sorularına güvenli, deterministik ve eğitim amaçlı yanıtlar verir. Kesin yatırım talimatı vermez. Kullanıcının cihazındaki özet finans verisi gönderilirse yalnızca toplulaştırılmış değerleri kullanır.
2. **Gemini:** Kullanıcı ayarlardan kendi Gemini anahtarını girerse backend `gemini-3.5-flash-lite` ile daha doğal yanıt üretir. Anahtar güvenli cihaz deposunda tutulur, istek başlığında TLS üzerinden iletilir, backend loguna/veritabanına/iş yüküne yazılmaz ve hata telemetrisinden temizlenir.

Gemini erişilemez, sınıra takılır veya anahtar geçersizse koç yerel rehbere düşer ve kullanıcıya hangi modda cevap verdiğini söyler. Mevcut Anthropic sunucu yapılandırması geriye uyum için korunur fakat varsayılan değildir.

## 6. Geliştirme oturumu

Kimlik doğrulamayı tamamen kapatan gizli bir rota eklenmez. Bunun yerine kurulum komutu yerel Ed25519 anahtar çifti ve süreli geliştirme JWT'si üretir. Backend yalnızca geliştirme ortamında bu açık anahtarı kabul eder; Flutter tokenı çalışma zamanı tanımıyla alır. Anahtarlar ve token git'e girmez.

Bu, yerel fiş/koç testini çalıştırır; üretim hesap sistemi için haricî kimlik sağlayıcı entegrasyonu ayrı dağıtım kararıdır.

## 7. İstemci deneyimi

- Ayarlar ekranına “Maki Koç bağlantısı” kartı eklenir.
- Kullanıcı Gemini anahtarını gizli alanda girebilir, bağlantıyı sınayabilir ve silebilir.
- Kart açıkça “Yerel rehber çalışıyor” veya “Gemini bağlı” durumunu gösterir.
- Fiş ekranı OCR servisinin hazır olup olmadığını gösterir; model kurulmamışsa teknik hata yerine tek komutluk çözüm sunar.
- Koç cevabında “Yerel rehber” veya “Gemini destekli” etiketi bulunur.
- Kullanıcıya görünen `provider`, `job`, `kohort`, `percentile`, `optimizasyon` gibi sözcükler sade Türkçeye çevrilir.

Görsel yön mevcut 14 sayfalık orman tasarımına bağlı kalır: koyu orman yüzeyi, yaprak yeşili durum işaretleri, yüksek okunabilirlik ve Maki'nin patika metaforu. Yeni kartlar mevcut token sistemini kullanır; masaüstünde gereksiz genişlemez, yatay telefonda içerik kesilmez.

## 8. Borç planları ve duyarlı yerleşim

Önceki onaylı tasarım aynen uygulanır:

- Faizi azalt, küçük borçları kapat, aylık yükü hafiflet, dengeli ilerle ve elle sıralama hazır yolları.
- Kullanıcı planı oluşturma, adlandırma, kural seçme, kaydetme, düzenleme, kopyalama ve silme.
- Sabit yüksekliklerin kaldırıldığı doğal akış; 390x844, 844x390, 976x365 ve 1440x900 görünüm testleri.
- Kullanıcıya gösterilen yabancı/teknik finans terimlerinin günlük Türkçeye çevrilmesi.

## 9. Güvenlik ve gizlilik

- API anahtarı hiçbir cevap gövdesine dönmez, maskeli biçimde dahi loglanmaz.
- İstek başlığı gözlemlenebilirlik özelliklerine eklenmez.
- Yerel iş deposu kullanıcı kimliğine göre yalıtılır ve süre sonunda temizlenir.
- Ham fiş baytları sonuç içinde veya hata ayrıntısında yer almaz.
- `local` yürütme modu üretimde yapılandırma hatasıdır.
- Koç yanıtı eğitim amaçlı olduğunu belirtir; yüksek riskli finansal kararları kesin sonuç gibi sunmaz.

## 10. Doğrulama

Backend:

- Paddle adapter şema ve gerçek model duman testi.
- Yerel fiş işi için kabul, sorgulama, kullanıcı yalıtımı, temizleme ve hata testleri.
- Gemini başarılı yanıt, geçersiz anahtar, hız sınırı, zaman aşımı ve yerel geri dönüş testleri.
- Gizli anahtarın log/iş yükü/cevap içinde bulunmadığı sözleşme testleri.
- Ruff, mypy ve tüm pytest paketi.

Flutter:

- Anahtar kaydetme/silme/test etme ve güvenli depolama testleri.
- Fiş tarama başarı, inceleme, servis hazır değil ve bozuk görsel testleri.
- Koç yerel/Gemini durum etiketleri.
- Borç planı alan ve widget testleri.
- Sade Türkçe yasaklı terim taraması.
- `dart analyze`, tüm Flutter testleri ve web debug derlemesi.

Uçtan uca teslimde tek PowerShell komutu yerel backend'i, süreli oturumu ve Flutter web uygulamasını başlatır; ayrı sağlık komutu OCR ve koç yeteneklerini raporlar.
