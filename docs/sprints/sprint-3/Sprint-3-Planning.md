# Sprint 3 Planlama

**Tarih:** 20 Temmuz 2026 · **İlk kapasite tahmini:** 100 SP · **Nihai kapsam:** 157 SP

## Hedef

Seçilen finans amacını ürünün gerçek davranışına dönüştürmek, günlük finans takibini
Yaşayan Finans Ormanı ile sürdürülebilir hâle getirmek ve Android/iOS/web kaynaklarını
güvenli bir GitHub teslimine hazırlamak.

## Öncelik sırası

1. Navigasyon kararlılığı, veri bütünlüğü ve cihaz içi gizlilik
2. Dört rota için farklı ana ekran, görev ve öneriler
3. Takvim, seri, görev kataloğu ve orman ekonomisi
4. Hedef oluşturma, harita ve işleme bağlı hedef katkısı
5. OCR, rapor, enflasyon ve borç araçlarının ürünleştirilmesi
6. Mobil/web responsive kalite ve tema bütünlüğü
7. Otomatik testler, yayın belgeleri ve temiz teslim paketi

## Ürün kararları

- Navigasyon sabit kalır; içerik seçilen amaca göre değişir.
- Gelir ve gider varsayılan olarak hedefi etkilemez; kullanıcı işlem sırasında açıkça
  seçerse etkiler.
- Aynı hedefte aynı kilometre taşı yalnız bir kez ödül verir.
- PDF finans verisini sunucuya göndermeden cihazda üretilir.
- Android dosya kaydı geniş depolama izni yerine sistem dosya seçicisini kullanır.
- Teknik/debug ölçümler kullanıcı arayüzünde gösterilmez.
- Veri yetersizken tahmin veya enflasyon sonucu uydurulmaz.

## Riskler ve önlemler

| Risk | Önlem |
|---|---|
| Çok özellikli ekranlarda telefon kilitlenmesi | Tembel ekran oluşturma, güvenli yönlendirme ve azaltılmış hareket |
| Rota seçiminin kozmetik kalması | Ana kart, görev ailesi, öneri ve analiz önceliğini ortak rota profiline bağlama |
| Orman ekonomisinin hızla anlamsızlaşması | Deterministik ödül defteri, fiyat katmanları ve kalıcı tüketim alanı |
| Hedef ödülü manipülasyonu | Hedef ve kilometre taşı başına kalıcı yüksek-su işareti |
| OCR'nin yanlış toplamı kaydetmesi | Güven eşiği, düzenlenebilir onay ve otomatik kayıt sınırı |
| Android PDF'nin kaybolması | Storage Access Framework ile kullanıcının konumu seçmesi |
| Teslime sır veya yerel veri girmesi | Özel dışlama listesi, sır taraması ve ZIP içerik doğrulaması |

## Tamamlanma tanımı

Kritik kullanıcı akışları testli, analiz temiz, web ve Android derlemeleri başarılı,
gizlilik sınırları belgeli ve teslim paketi tekrar üretilebilir olmalıdır.
