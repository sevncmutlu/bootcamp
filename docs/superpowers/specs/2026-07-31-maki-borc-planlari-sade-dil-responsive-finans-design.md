# Maki Borç Planları, Sade Dil ve Duyarlı Finans Paneli Tasarımı

Tarih: 31 Temmuz 2026

## 1. Amaç

Maki'nin borç kapatma deneyimini iki hazır yöntemden kapsamlı fakat anlaşılır bir planlama aracına dönüştürmek; kullanıcının kendi ödeme planını kurup cihazında saklayabilmesini sağlamak; finans ekranındaki kısa ve yatay web görünümü kesilmesini gidermek; müşteriye görünen teknik dili günlük Türkçeye çevirmek.

Başarı ölçütleri:

- Kullanıcı en az beş hazır ödeme yolundan birini seçebilir.
- Kullanıcı kurallı veya elle sıralanmış kendi planını oluşturabilir, düzenleyebilir, silebilir ve tekrar kullanabilir.
- Her plan aynı borç verisiyle deterministik sonuç üretir.
- 976×365 web, 844×390 yatay telefon ve 390×844 dikey telefon görünümlerinde içerik kesilmez.
- Kullanıcı ekranlarında `kohort`, `percentile` ve `optimizasyon` gibi açıklamasız teknik terimler kalmaz.

## 2. Seçilen yaklaşım

Seçilen çözüm, yönlendirmeli kural oluşturucuyla elle ödeme sırasını tek deneyimde birleştiren A+B yaklaşımıdır.

- Yalnız elle sıralama, farklı finansal hedefleri açıklamakta yetersiz kalır.
- Tam koşul/formül oluşturucu, müşteri uygulaması için gereksiz bilişsel yük ve hata alanı oluşturur.
- Yönlendirmeli oluşturucu, güçlü kuralları günlük cümlelere çevirir; isteyen kullanıcı aynı akışta ödeme sırasını kendisi belirler.

## 3. Hazır ödeme yolları

Her hazır yol, kullanıcıya sonuç ve niyet üzerinden anlatılır. Teknik ad yalnız açıklayıcı alt metinde gerektiğinde gösterilir.

1. **Faizi azalt**
   - Önce yıllık faiz oranı en yüksek borca ek ödeme gider.
   - Eşitlikte kalan borcu daha düşük olan öne alınır.
   - Ek para seçilen ilk borca odaklanır.

2. **Küçük borçları kapat**
   - Önce kalan borcu en düşük hesap kapatılır.
   - Eşitlikte faiz oranı yüksek olan öne alınır.
   - Ek para seçilen ilk borca odaklanır.

3. **Aylık yükü hafiflet**
   - Tahmini kapanış süresi `kalan borç / asgari ödeme` en düşük olan borç öne alınır.
   - Eşitlikte asgari ödemesi yüksek olan öne alınır.
   - Amaç, bir asgari ödemeyi erken kaldırıp sonraki aylara hareket alanı açmaktır.

4. **Dengeli ilerle**
   - Asgari ödemelerden sonra kalan ek para, açık borçlar arasında eşit paylaştırılır.
   - Yuvarlama farkı sırasıyla faiz oranı yüksek borçlara verilir.

5. **Sırayı ben belirleyeceğim**
   - Kullanıcı borçları sürükleyerek ödeme önceliğini belirler.
   - Ek para listedeki ilk açık borca odaklanır.
   - Sonradan eklenen veya kaydedilmiş sırada bulunmayan borçlar listenin sonuna; faiz oranı yüksek olan önce gelecek şekilde eklenir.

Hazır yollar silinemez. Kullanıcı bunları kendi planına başlangıç noktası olarak kopyalayabilir.

## 4. Kendi planını oluşturma deneyimi

Borç kapatma ekranında hazır yöntemlerin sonunda, patika çizgisi ve Maki işareti taşıyan **Kendi yolunu çiz** kartı bulunur. Bu, tasarımın ayırt edici öğesidir; yerel orman/patika dili finans kararını bir rota olarak anlatır.

Oluşturucu tek, kaydırılabilir alt panelde dört anlaşılır bölüm içerir:

1. **Planın adı** — 2–40 karakter, cihazdaki diğer planlardan farklı olmalıdır.
2. **Önce hangisi?** — yüksek/düşük faiz, yüksek/düşük kalan borç, yüksek/düşük asgari ödeme, kısa tahmini kapanış veya sıralamayı kendim belirleyeceğim.
3. **Eşitlik olursa** — aynı ölçütlerden, ilk seçimden farklı bir ikinci kural.
4. **Ek param nasıl dağılsın?** — ilk borca odaklan veya açık borçlara eşit paylaştır.

Panel seçimleri anlık olarak tek cümlede özetler:

> Ek paran önce faiz oranı yüksek borca gider; eşitlikte kalan borcu düşük olan öne geçer.

Elle sıralama seçilirse borç listesi sürüklenebilir hâle gelir. Henüz borç yoksa plan kaydedilebilir; sıra, ilk borçlar eklendiğinde tamamlanır.

Kaydedilmiş planlar hazır yolların altında **Planlarım** bölümünde görünür. Kullanıcı seçebilir, düzenleyebilir, kopyalayabilir veya silebilir. Seçili plan silinirse uygulama güvenli varsayılan olan **Faizi azalt** yoluna döner ve bunu kısa bir bildirimle açıklar.

## 5. Veri modeli ve saklama

Yeni, bağımsız bir `DebtPlanDefinition` alan modeli kullanılır:

- `id`
- `name`
- `primaryCriterion`
- `primaryDirection`
- `tieBreakerCriterion`
- `tieBreakerDirection`
- `allocationMode` (`focused` veya `equal`)
- `manualDebtOrder`
- `isBuiltIn`
- `schemaVersion`

Hazır planlar kodda değişmez tanımlar olarak tutulur. Kullanıcı planları küçük ve cihaz ayarı niteliğinde olduğu için sürümlü JSON olarak `SharedPreferences` içinde saklanır. Bu tercih Android, iOS ve webde aynı davranışı sağlar; veritabanı şeması göçü gerektirmez. Hatalı veya eski kayıt uygulamayı durdurmaz: geçerli planlar yüklenir, okunamayan kayıt atlanır ve kullanıcıya genel bir “Bir plan okunamadı” bildirimi gösterilir.

`DebtPlanLocalDataSource`, yalnız kayıt/okuma/silme ve şema dönüşümünden sorumludur. BLoC plan seçimini ve düzenleme olaylarını yönetir. Finans çekirdeği planı yalnız sıralama ve dağıtım kuralları olarak tüketir; kullanıcı arayüzü metinlerine bağımlı olmaz.

## 6. Hesaplama çekirdeği

Mevcut `DebtStrategy` ikilisi, geriye uyum için korunurken genel `DebtPlan` yürütme yolu eklenir. Avalanche ve snowball, genel planın hazır tanımlarına dönüştürülür; eski çağrılar aynı sonuçları üretmeye devam eder.

Aylık hesap sırası:

1. Faizleri hesapla.
2. Her borcun asgari ödemesini ayır.
3. Seçilen planla açık borçları deterministik sırala.
4. `focused` ise tüm ek parayı sıradaki borca, kalan parayı sonraki borca aktar.
5. `equal` ise ek parayı açık borçlara eşit dağıt; kuruş farklarını tanımlı bağlayıcı kuralla dağıt.
6. Kapanan borçları sonraki ay aktif listeden çıkar.

Her karşılaştırmanın son bağlayıcısı borç kimliğidir. Böylece aynı girdi her platformda aynı ödeme takvimini üretir.

## 7. Borç ekranı arayüzü

- “Borç Ödeme Simülatörü” başlığı **Borç Kapatma Planı** olur.
- “Ödeme Stratejisi” etiketi **Ödeme yolu** olur.
- İlk ekranda dört ana hazır yol kısa kartlar olarak gösterilir; elle sıralama ve kendi planı belirgin ikinci satırdadır.
- Seçili kart, yalnız renk değil onay işareti ve “Seçili” metniyle belirtilir.
- Kart açıklamaları en fazla iki kısa cümledir.
- Sonuç alanı seçilen yolun adını, borçsuz kalınacak ayı, toplam faizi ve ilk üç ödeme adımını gösterir.
- “Diğer yollarla karşılaştır” eylemi hazır yolları aynı girdiyle hesaplayıp ay ve faiz farkını sade bir tabloyla sunar.
- Finansal yönlendirme kesin vaat olarak yazılmaz; sonuçların girilen oran ve ödemelere dayalı tahmin olduğu belirtilir.

## 8. Sade müşteri dili

Türkçe kullanıcı metinlerinin kaynağı `app_tr.arb` olur; üretilen yerelleştirme dosyaları doğrudan elle düzenlenmez. Kod içindeki kullanıcıya görünen sabit Türkçe metinler de aynı taramaya dâhildir.

Onaylanan temel dönüşümler:

- `Anonim kohort: 24` → `Sizinle benzer 24 kişi`
- `Kohort henüz yeterli değil` → `Karşılaştırma için henüz yeterli kişi yok`
- `Tasarruf Liderlik Tablosu` → `Tasarruf sıralaması`
- `En İyi %20` → `Benzer kullanıcılar arasında ilk %20`
- `Akıllı Yapay Zekâ Optimizasyonunu Etkinleştir` → `Bildirim için en uygun zamanı seç`
- `Borç Ödeme Simülatörü` → `Borç Kapatma Planı`
- `Ödeme Stratejisi` → `Ödeme yolu`

Dil kuralı: kullanıcı bir seçimi yapabilmek için teknik terimi bilmek zorunda kalmamalıdır. Gerekli teknik kavram, gündelik başlığın altında tek cümleyle açıklanır. İç API, model ve analitik adları değiştirilmez.

## 9. Finans ana ekranındaki kesilme düzeltmesi

Sorunun kaynağı, geniş veya kısa görünümde overview alanının sabit `274` piksel yüksekliğe zorlanmasıdır. Amaç kartı daha yüksek olduğunda tab seçici kartın üzerine gelir.

Yeni yapı:

- Sayfa `NestedScrollView` kullanır.
- Haftalık takvim ve amaç kartı doğal yüksekliğe sahip bir üst içerik alanında bulunur.
- Gider/Gelir seçici, üst içerik kaydırıldıktan sonra görünür kalan sabit başlık olur.
- İşlem listeleri kendi sekmelerinde tembel yüklenen kaydırılabilir listeler olarak kalır.
- 720 piksel ve üzerinde takvimle amaç kartı iki sütundur.
- Görünüm yüksekliği 600 pikselden azsa amaç kartı kompakt sunulur: görevler iki satırda sarılır, Maki notu tek satırlık açılır bölüme dönüşür.
- Dikey telefonda takvim üstte, amaç kartı altta mevcut sırasını korur.
- Sabit `274` ve `430` yükseklikleri kaldırılır; klavye açıldığında da içerik kaydırılabilir kalır.

## 10. Hata durumları ve erişilebilirlik

- Boş, yinelenen veya 40 karakteri aşan plan adı kaydedilmez; sorun alanın altında açıklanır.
- İlk ve ikinci kural aynı olamaz.
- Geçersiz manuel borç kimlikleri yok sayılır; yeni borçlar güvenli bağlayıcı kuralla sona eklenir.
- Ek bütçe sıfırdan büyük değilse simülasyon çalışmaz ve alan yanında çözüm gösterilir.
- Tüm seçim kartları klavye odağı, semantik seçili durumu ve en az 44×44 dokunma alanı taşır.
- Renk, seçim durumunun tek göstergesi değildir.
- Hareket azaltma ayarında patika/işaret geçişleri animasyonsuz tamamlanır.

## 11. Test ve doğrulama

Finans çekirdeği:

- Beş hazır yolun sıralama ve dağıtım sonuçları.
- Eşit faiz/bakiye/asgari ödeme bağlayıcıları.
- Eşit dağıtımda kuruş farkları.
- Manuel listede eksik ve artık borç kimlikleri.
- Eski avalanche/snowball çağrılarının geriye uyumu.

Uygulama katmanı:

- Plan oluşturma, düzenleme, kopyalama, silme ve yeniden yükleme.
- Bozuk sürümlü JSON kaydından güvenli dönüş.
- Seçili özel plan silinince varsayılana dönüş.
- Türkçe metinlerde yasaklı müşteri terimleri için sözleşme testi.

Arayüz:

- 390×844 dikey telefon.
- 844×390 yatay telefon.
- 976×365 kısa web görünümü.
- 1440×900 masaüstü web görünümü.
- Klavye açıkken plan oluşturucu ve gelir/gider formları.
- Altın görsel testiyle amaç kartı, takvim ve sabit sekme ilişkisi.

Teslim kapıları: `dart analyze lib test`, tüm Flutter testleri, web debug derlemesi ve açık tarayıcıda görsel/konsol doğrulaması.

## 12. Kapsam dışı

- Serbest metinle matematiksel formül yazma.
- Bulut eşitleme ve hesaplar arası plan paylaşımı.
- Kullanıcının planını finansal danışman tavsiyesi olarak yayımlama.
- Bu çalışma için backend şeması veya API değiştirme.
