# Sevinç için GitHub Teslim Paketi Tasarımı

**Tarih:** 1 Ağustos 2026

**Ürün:** Maki Finans Koçu
**Teslim türü:** GitHub'a doğrudan yüklenebilir temiz kaynak kod paketi

## Amaç

Sevinç'e, Maki Finans Koçu'nun güncel durumunu eksiksiz anlatan, güvenli biçimde
paylaşılabilen ve açıldıktan sonra GitHub deposu olarak kullanılabilen tek bir ZIP
dosyası teslim etmek. Paket hem ürün sunumuna hem de geliştirici incelemesine uygun
olacak; yerel çalışma ortamına ait atıklar veya gizli bilgiler içermeyecek.

## Paket kapsamı

ZIP aşağıdaki sürümlenebilir içerikleri kapsar:

- Flutter Android, iOS ve web kaynak kodu;
- FastAPI backend kaynak kodu ve testleri;
- ortak deterministik finans çekirdeği;
- API ve hata sözleşmeleri;
- CI iş akışları, güvenlik kuralları ve altyapı tanımları;
- çalıştırma, doğrulama ve yayın scriptleri;
- tasarım sistemi, ürün görselleri ve gerekli uygulama varlıkları;
- README, Product Backlog, sprint belgeleri, günlük notlar ve teknik kanıtlar;
- bağımlılık kilit dosyaları ve örnek yapılandırmalar.

## Paket dışında bırakılacaklar

Aşağıdaki içerikler GitHub'a gönderilmez ve ZIP'e alınmaz:

- `build/`, `.dart_tool/`, `.gradle/`, `Pods/` ve derleme önbellekleri;
- `.logs/`, `tmp/`, test cache'leri ve yerel geliştirme çıktıları;
- `.env`, `key.properties`, `*.jks`, erişim belirteçleri ve özel anahtarlar;
- yerel veritabanları, kullanıcı finans verileri ve OCR için yüklenen özel fişler;
- APK, AAB, IPA ve diğer ikili dağıtım çıktıları;
- IDE'ye veya tek bir cihaza bağlı geçici ayarlar.

## Belge güncelleme modeli

Ana README ürünün güncel yeteneklerini, mimarisini, hızlı başlangıç adımlarını,
platform durumunu ve gizlilik sınırını tek giriş noktası olarak anlatır. Frontend ve
backend README dosyaları kendi çalışma alanlarına özgü komutları içerir.

Product Backlog, tamamlanan özellikleri gerçekte çalışan akışlarla eşleştirir. Sprint
3 için Planning, Backlog, Daily Scrum Notes, Review ve Retrospective belgeleri
oluşturulur; eski sprint kayıtlarının tarihsel içeriği korunur. Kök `Sprint-3.md`
sunum özeti görevi görür. `CHANGELOG.md` ürün değişikliklerini, `DELIVERY.md` ise
Sevinç'in paketi açtıktan sonra izleyeceği teslim kontrol listesini içerir.

## Doğrulama

Paketleme öncesinde:

1. Flutter statik analizi hatasız tamamlanır.
2. Flutter testlerinin tamamı geçer.
3. Web release derlemesi başarıyla üretilir.
4. Kaynak ağaçta gizli dosya desenleri ve yanlışlıkla eklenmiş yerel çıktılar taranır.
5. ZIP açılarak gerekli kök dosyaların bulunduğu ve dışlanması gereken desenlerin
   bulunmadığı doğrulanır.
6. ZIP için boyut ve SHA-256 özeti oluşturulur.

Test ve derleme çıktıları teslim belgelerinde tarihli kanıt olarak özetlenir; üretilen
`build/` klasörleri ZIP'e eklenmez.

## ZIP yapısı

ZIP açıldığında tek bir kök klasör bulunur:

```text
Maki-Finans-Kocu-GitHub-Teslim-2026-08-01/
  README.md
  DELIVERY.md
  CHANGELOG.md
  Product-Backlog.md
  Sprint-1.md
  Sprint-2.md
  Sprint-3.md
  frontend/
  backend/
  packages/
  contracts/
  docs/
  infra/
  security/
  scripts/
  tests/
  .github/
```

## Kabul ölçütleri

- ZIP, GitHub'a yüklenebilecek yalnızca sürümlenebilir dosyaları içerir.
- Belgelerde web desteğinin kaldırıldığına dair eski ve yanlış ifade kalmaz.
- Yaşayan Finans Ormanı, 325 görev, hedef haritası, hedefe bağlı işlemler, takvim
  serisi, mağaza, yerel PDF raporları, OCR ve Maki Koç güncel durumları belgelenir.
- Gizlilik iddiaları uygulamanın gerçek sınırlarıyla çelişmez.
- Canlı servis anahtarları ve mağaza imzaları tamamlanmış gibi gösterilmez.
- ZIP'in SHA-256 değeri teslim mesajında paylaşılır.

## Hata ve güvenlik yaklaşımı

Paket oluşturma işlemi kaynak klasörü değiştirmez. Ayrı bir hazırlama klasörüne
yalnızca izin verilen dosyalar kopyalanır. Dışlama denetiminde gizli anahtar, `.env`,
yerel veritabanı veya cache bulunursa ZIP teslim edilmez; içerik temizlendikten sonra
yeniden oluşturulur.
