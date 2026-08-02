# Video Demo Oturumu ve README Sprint 3 Tasarımı

## Amaç

Maki'nin Android emülatöründe video çekimine hazır, kullanıcıdan giriş veya
"güvenli oturum" işlemi istemeyen bir geliştirme sürümü çalıştırılacak. Bu kolaylık
yalnızca development/debug yapılandırmasıyla sınırlı kalacak; production kimlik ve
release doğrulamaları değiştirilmeden korunacak.

README yeniden yazılmayacak. GitHub `main` dalındaki mevcut README (dosya blob'u
`2e404b5f74c2784cbeb771d4179c72282bf8a0dc`) temel alınacak, mevcut Sprint 1 ve
Sprint 2 anlatımı aynen korunacak, Sprint 3 bölümü gerçekleşen teslim durumunu
yansıtacak şekilde güncellenecek. Takım listesine `Sena Gemiçioğlu: Developer`
eklenecek.

## Değerlendirilen Yaklaşımlar

1. **Önerilen: development token ile otomatik debug oturumu.** Yerel backend kısa
   ömürlü, asimetrik imzalı geliştirme tokenı üretir; APK bu token ve development
   backend adresiyle derlenir. Video sırasında giriş ekranı veya güvenli oturum
   uyarısı oluşmaz. Production davranışı etkilenmez.
2. **Kimliği uygulama genelinde kaldırmak.** En kısa görünen yoldur ancak korumalı
   API'leri ve production güvenlik sınırını bozar; uygulanmayacaktır.
3. **Tamamen çevrimdışı demo.** Oturum uyarılarını kaldırır ancak OCR, çevrimiçi
   koç ve backend'e bağlı özellikleri çalıştıramaz; "her şeyi çalıştır" hedefini
   karşılamaz.

## Çalıştırma Mimarisi

- `scripts/create_dev_session.py`, yerel development anahtarıyla geçici JWT üretir.
- Backend aynı public key, issuer ve audience değerleriyle `127.0.0.1:8000`
  üzerinde başlatılır.
- Android emülatörü backend'e `http://10.0.2.2:8000` üzerinden ulaşır.
- Flutter debug APK şu derleme tanımlarını alır:
  - `MAKI_ENV=development`
  - `BACKEND_URL=http://10.0.2.2:8000`
  - `MAKI_ACCESS_TOKEN=<geçici-development-tokenı>`
- Token kaynak koda, README'ye, commit'e veya teslim paketine yazılmaz.
- OIDC tanımları debug video akışında kullanılmaz; production release kapıları
  olduğu gibi kalır.

## README Birleştirme Kuralı

- GitHub `main` README'nin sırası, başlıkları, Sprint 1 ve Sprint 2 içeriği korunur.
- Takım elemanlarına yalnızca `Sena Gemiçioğlu: Developer` satırı eklenir.
- Sprint 3'ün `Planlandı` durumu `Tamamlandı` olarak güncellenir ve güncel ürün
  kapsamı, test/cihaz doğrulaması ve dürüst platform sınırları kısa maddelerle
  eklenir.
- README, mevcut geliştirme dalındaki tamamen yeniden yazılmış metin üzerinden
  sürdürülmez.
- Bu görevde GitHub'a push yapılmaz.

## Hata Davranışı

- Backend sağlık kontrolü geçmeden APK başlatılmış sayılmaz.
- Token üretimi veya backend başlangıcı başarısızsa eski/boş oturumla devam
  edilmez; hata günlükleri gösterilir.
- Emülatör bağlı değilse APK üretilir fakat kurulum başarısızlığı açıkça raporlanır.
- Debug token herhangi bir kullanıcı arayüzü metninde veya komut çıktısında
  paylaşılmaz.

## Doğrulama

- Backend canlılık ve yetenek uçları HTTP 200 döndürür.
- APK development tanımlarıyla başarıyla derlenir ve emülatöre kurulur.
- Uygulama açılışında giriş/güvenli oturum adımı görülmez.
- Korumalı bir backend özelliği development tokenıyla yetkili yanıt alır.
- Flutter analiz ve ilgili testler başarılı olur.
- README farkında Sprint 1/Sprint 2 metninin korunduğu, Sprint 3'ün güncellendiği
  ve Sena Gemiçioğlu'nun geliştirici olarak eklendiği doğrulanır.
- `git status` ve diff ile hiçbir erişim belirtecinin izlenen dosyalara yazılmadığı
  kontrol edilir.

