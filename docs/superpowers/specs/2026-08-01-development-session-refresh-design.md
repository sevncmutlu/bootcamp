# Maki Test Oturumu Yenileme Tasarımı

## Amaç

USB üzerinden yerel backend'e bağlanan Android test sürümünde fiş taramanın,
telefonda daha önce saklanmış süresi dolmuş bir geliştirme anahtarı yüzünden
`401 Oturum doğrulanamadı` hatasına düşmesini engellemek.

## Kök neden

`AuthLocalDataSourceImpl`, güvenli depodaki anahtarı APK'ya derleme zamanında
eklenen `MAKI_ACCESS_TOKEN` değerinden önce okuyor. APK veri kaybetmeden yeniden
kurulduğunda güvenli depodaki bir saatlik eski anahtar korunuyor ve yeni APK
anahtarı hiç kullanılmıyor. Backend bu süresi dolmuş JWT'yi doğru biçimde
reddediyor.

## Seçilen yaklaşım

Yalnız bir test anahtarı APK'ya açıkça eklenmişse bu değer güvenli depodaki
değerden önce kullanılacak. Üretim oturum akışı ve OIDC davranışı değişmeyecek.

Geliştirme anahtarı üreticisine sınırlandırılmış bir `--ttl-seconds` seçeneği
eklenecek. Varsayılan bir saat korunacak; telefona kurulan test APK'sı için yedi
gün (`604800` saniye) istenecek. Böylece genel geliştirme güvenlik varsayımı
gevşetilmeden telefon testi için makul bir süre sağlanacak.

## Veri akışı

1. Geliştirme anahtar çifti mevcut `.local/dev-auth` dizininden okunur.
2. APK derlemesi için yedi günlük, imzalı bir JWT üretilir.
3. JWT `MAKI_ACCESS_TOKEN` derleme tanımıyla test APK'sına eklenir.
4. `AuthLocalDataSourceImpl`, boş olmayan derleme anahtarını önce döndürür.
5. `SessionRepository` bu yolu yalnız üretim dışı, OIDC'siz geliştirme
   oturumunda kullanır.
6. Fiş tarama isteği aynı backend anahtar çiftiyle doğrulanır.

## Güvenlik sınırları

- Bu davranış yalnız APK'ya açıkça bir `MAKI_ACCESS_TOKEN` eklendiğinde etkin.
- Üretim sürümüne test anahtarı eklenmeyecek.
- Üretimde backend hâlâ HTTPS ve gerçek OIDC erişim anahtarı gerektirir.
- Anahtar ömrü en fazla yedi günle sınırlandırılır.
- APK yeniden kurulurken gelir, gider, amaç ve ayar verileri silinmez.
- Anahtar veya JWT test çıktılarında ve günlüklerde yazdırılmaz.

## Hata davranışı

- Derleme anahtarı yoksa mevcut güvenli depolama davranışı aynen devam eder.
- Test anahtarı süresi dolarsa backend yine kapalı güvenlikle `401` döndürür;
  yeni test APK'sı üretilir.
- Backend kapalıysa oturum hatası yerine mevcut bağlantı hatası gösterilir.

## Doğrulama

- Birim testi: Güvenli depoda eski anahtar ve APK'da yeni anahtar varken yeni
  anahtar seçilir.
- Birim testi: APK anahtarı yokken güvenli depodaki anahtar kullanılmaya devam
  eder.
- Python testi/CLI kontrolü: İstenen TTL tokenın `exp - iat` aralığına yansır ve
  izin verilen üst sınır aşılamaz.
- Backend doğrulaması: Yeni tokenla kimlik gerektiren bir istek `401` vermez.
- Android doğrulaması: APK `adb install -r` ile veri silmeden kurulur; fiş tarama
  isteği backend'de `202 Accepted` üretir.

## Kapsam dışı

- Production backend dağıtımı.
- Google/Apple/OIDC hesap kurulumu.
- USB bağlantısı olmadan yerel bilgisayardaki backend'e erişim.
