# Sprint 3 — Kişiselleştirme, Yaşayan Finans Ormanı ve Teslim

**Proje:** Maki Finans Koçu · **Takım:** Takım 120
**Tarih:** 20 Temmuz – 1 Ağustos 2026 · **Durum:** Tamamlandı

> **Sprint teması:** Maki'yi seçilen finans amacına gerçekten uyarlanan, finansal
> davranışı görünür ilerlemeye dönüştüren ve Android/iOS/web kaynaklarıyla teslim
> edilebilen bir ürüne dönüştürmek.

## Sprint hedefi

Kullanıcıya farkındalık, hedef, borç veya öğrenme rotalarından birini seçtirip ana
ekranı, görevleri, önerileri ve analiz önceliğini bu karara göre değiştirmek; Yaşayan
Finans Ormanı'nı takvim, seri, görev, hedef ve ödül ekonomisiyle ürünün merkezine
yerleştirmek; kritik mobil kararlılık ve teslim belgelerini tamamlamak.

## Sonuç

| Ölçüt | Sonuç |
|---|---|
| Planlanan / tamamlanan | 170 / 170 SP |
| Flutter statik analiz | Hatasız |
| Flutter testleri | 178 / 178 başarılı |
| Backend kalite | Ruff/mypy temiz; 224 test başarılı, Docker'a bağlı 9 test atlandı |
| Finans çekirdeği | Fatal analiz temiz; 56 / 56 test başarılı |
| Web | Sentetik, in-memory preview release derlemesi ve Chromium açılışı başarılı |
| Android | Debug APK başarılı; temel sürüm fiziksel cihazda doğrulandı |
| iOS | Kaynak ve proje yapısı hazır; imza/doğrulama macOS gerektirir |
| Gizlilik | Finans kaydı ve PDF üretimi cihaz içinde |

Sprint 3'te kapsam, kullanıcı geri bildirimleriyle başlangıçtaki 100 SP tahmininin
üzerine çıktı. Yeni kapsam ayrı backlog kalemlerine bölündü ve tamamlanmadan sprint
kapatılmadı.

## Öne çıkan teslimler

- Dört amaca göre kişiselleşen finans deneyimi
- 325 benzersiz görev, seri, XP, tohum cüzdanı ve orman mağazası
- Tam ekran Yaşayan Finans Ormanı ve 30 duraklı hedef haritası
- Hedefe bağlanabilen gelir/giderler ve güvenli geri alma
- PaddleOCR fiş toplamı onayı ve gider taslağı
- Cihaz içi günlük/haftalık/aylık PDF rapor merkezi
- Android için izin gerektirmeyen sistem “Farklı kaydet” akışı
- Sürüklenebilir ve konumunu hatırlayan Maki Koç balonu
- Responsive web/telefon gezinmesi, tema bütünlüğü ve düşük cihaz kararlılığı
- Kuruş tabanlı Int64 veritabanı migration'ı, gerçek OS bildirim planlaması, yerel
  Laspeyres fiyat sepeti ve dayanıklı yerel harcama tahmini
- Web'i sentetik veriyle sınırlayan preview modu ve eksik production ayarında derlemeyi
  reddeden fail-closed release kapıları

## Sprint belgeleri

- [Sprint 3 Planlama](./Sprint-3/Sprint-3-Planning.md)
- [Sprint 3 Backlog](./Sprint-3/Sprint-3-Backlog.md)
- [Günlük İlerleme Notları](./Sprint-3/Daily-Scrum-Notes.md)
- [Sprint 3 Review](./Sprint-3/Sprint-3-Review.md)
- [Sprint 3 Retrospective](./Sprint-3/Sprint-3-Retrospective.md)
- [Teslim Kontrolü](./DELIVERY.md)

## Tamamlanma tanımı

- Kullanıcı akışları hata, boş ve yükleniyor durumlarıyla tamamlandı.
- Seçilen rota ölçülebilir biçimde ana ekranı ve günlük görevleri değiştiriyor.
- Finansal etkiler açık kullanıcı seçimine dayanıyor ve silmede geri alınıyor.
- Cihaz içi veriler istemeden ağa gönderilmiyor.
- Flutter analiz/test kapıları ve Android/web derlemeleri geçiyor.
- README, backlog, sprint, changelog ve teslim belgeleri güncel.

**Sonuç:** Sprint hedefi ve teslim kapsamı karşılandı.
