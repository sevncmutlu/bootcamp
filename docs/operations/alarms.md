# Alarm müdahalesi

Alarm susturulmadan önce zaman aralığı, etkilenen sürüm ve istek kimlikleri olay kaydına eklenir.
Kişisel veri, istek gövdesi ve sağlayıcı sırrı kanıta yazılmaz.

## Yüksek 5xx oranı

Eşik yüzde 1, süre 5 dakika, önem `critical`. Olası neden son dağıtım, veri tabanı havuzu veya
beklenmeyen uygulama hatasıdır.

1. `/health/ready` ile PostgreSQL ve Redis durumunu kontrol et.
2. Sürüm digestini ve son dağıtım zamanını karşılaştır.
3. Hata kodlarını route şablonuna göre grupla; gövde veya kullanıcı değeri arama.

## Yüksek kuyruk yaşı

Eşik p95 30 saniye, süre 10 dakika, önem `warning`. Olası neden durmuş dispatcher, yetersiz işçi
veya sağlayıcı yavaşlığıdır.

1. Dispatcher ve ilgili işçi healthcheck sonucunu kontrol et.
2. Kuyruk türüne göre bekleyen ve hatalı iş sayılarını karşılaştır.
3. İşçi CPU/bellek sınırı ile sağlayıcı gecikmesini kontrol et.

## Hatalı iş artışı

Eşik 5 dakikada 5 kalıcı hata, önem `critical`. Olası neden bozuk mesaj, model uyumsuzluğu veya
sağlayıcı sözleşme değişikliğidir.

1. `error.code` ve `job.kind` dağılımını kontrol et.
2. Dead-letter girdilerinde yalnızca kimlik ve hata kodu bulunduğunu doğrula.
3. Son model, şema ve işçi sürümünü karşılaştır; tekrar oynatmayı sonra değerlendir.

## Sağlayıcı zaman aşımı

Eşik saniyede 0,1 olay, süre 10 dakika, önem `warning`. Olası neden sağlayıcı kesintisi, ağ veya
yanlış timeout ayarıdır.

1. Hangi iş türünün hata verdiğini ve retry sayısını kontrol et.
2. Sağlayıcının resmi durum sayfasını ve ağ çıkışını kontrol et.
3. Devre kesici etkisini ölç; timeout değerini olay sırasında yükseltme.

## Gizlilik reddi artışı

Eşik 15 dakikada 20 ret, süre 5 dakika, önem `warning`. Olası neden istemci sözleşme gerilemesi
veya kötüye kullanım denemesidir.

1. Route şablonu ve uygulama sürümüne göre retleri grupla.
2. OpenAPI farkını ve son mobil sürümü kontrol et.
3. Ham değerleri açmadan yalnızca reddedilen alan yolunu incele.

## Hazırlık denetimi düşüşü

Eşik 2 dakika boyunca 503, önem `critical`. Olası neden PostgreSQL, Redis veya bağlantı havuzu
kesintisidir.

1. Hazırlık yanıtındaki bağımlılık durumlarını kontrol et.
2. Stateful servis healthcheck ve kaynak sınırlarını kontrol et.
3. Trafiği hazır örneklere yönlendir; liveness yeniden başlatmasını son çare olarak kullan.
