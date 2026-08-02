# README Ürün Ekranları Tasarımı

Tarih: 2 Ağustos 2026

## Amaç

README içinde Maki'nin güncel ürün kalitesini ilk bakışta göstermek için kullanıcının
sağladığı iki gerçek Android ekran görüntüsünü kullanmak. Kapsam yalnız ana finans
ekranı ve Yaşayan Maki Ormanı ekranıdır.

## Seçilen yaklaşım

İki portre ekranı, Sprint 3 bölümünde `Uygulamadan Görüntüler` başlığı altında yan
yana gösterilecektir. Görsellerin gerçek piksel içeriği korunacak; cihaz çerçevesi,
yapay arka plan, filtre veya üretken görsel eklenmeyecektir. Her ekranın altında
kısa ve anlaşılır bir başlık bulunacaktır.

## Dosya yapısı

- Ana finans ekranı:
  `docs/assets/screenshots/sprint-3-ana-finans-ekrani.png`
- Yaşayan Maki Ormanı:
  `docs/assets/screenshots/sprint-3-yasayan-maki-ormani.png`

README bu dosyalara göreli yollarla bağlanacaktır. Böylece GitHub, ZIP teslimi ve
yerel önizleme aynı kaynakları kullanır.

## Yerleşim

- Bölüm, Sprint 3 tamamlanan kapsam listesinden hemen sonra yer alır.
- Ortalanmış HTML düzeni kullanılır.
- Her görsel `width="300"` ile sınırlandırılır; portre oranı korunur.
- Alternatif metinler sırasıyla `Maki ana finans ve hedef rotası ekranı` ve
  `Yaşayan Maki Ormanı ilerleme ekranı` olur.
- Dar GitHub görünümünde görseller doğal olarak alt satıra geçebilir; yatay kırpma
  yapılmaz.

## Kabul ölçütleri

- İki kaynak PNG repository içinde bulunur ve bozuk değildir.
- README içindeki iki göreli görsel yolu gerçek dosyalarla birebir eşleşir.
- Ana finans ve orman ekranları kırpılmadan, okunabilir ve aynı görsel genişlikte
  görünür.
- README'nin mevcut Sprint 1, Sprint 2 ve Sprint 3 anlatısı korunur.
- Değişiklik yalnız dokümantasyon ve ekran görüntüsü dosyalarıyla sınırlıdır.
