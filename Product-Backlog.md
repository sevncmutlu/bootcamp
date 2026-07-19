# 📋 Product Backlog — Maki Finans Koçu

**Takım:** Takım 120 · **Product Owner:** Emir Hüseyin İnci · **Scrum Master:** Sevinç Mutlu
**Product Backlog Aracı:** [Takım 120 Miro Backlog Board](https://miro.com/welcomeonboard/NXRRV0ovYXp6emtKV0lKWFdyUEZQSjhoNkVVMW5GdTRoVDRXZlNlci9VTXZvUzRwSDRBS2RWWEtRbVFCUE85ak9iQ09xYUhRUXpOR2hyaGdNdHA3a2tXRVlmR2hqbGFXcFp6RWVZemVzeU1BbnNDUVViaFpQc2E5U3VkSEowWldBd044SHFHaVlWYWk0d3NxeHNmeG9BPT0hdjE=?share_link_id=32213079148)

> Backlog; epic'lere ve epic'ler altında user story'lere bölünmüştür. Her story bir **öncelik** (🔴 Yüksek / 🟡 Orta / 🟢 Düşük), bir **story point (SP)** ve bir **hedef sprint** taşır.
>
> **Story Point (SP) nedir?** Bir işin efor + karmaşıklık + belirsizliğini gösteren göreli büyüklük birimidir (saat değildir). Fibonacci ölçeği kullanılır: 1, 2, 3, 5, 8, 13. Örn. 13 SP'lik bir iş, 5 SP'lik bir işten belirgin şekilde daha büyük/riskli demektir.

---

## 🧮 Puanlama & Dağıtım Mantığı

- **Toplam proje puanı:** ~300 SP (3 sprint × ~100 SP)
- Story point'ler **planning poker** ile göreli olarak (efor + belirsizlik + karmaşıklık) verilmiştir.
- Riskli işler (Türkçe fiş OCR doğruluğu, RAG kaynaklandırma) erken sprintlere çekilmiştir.
- Her sprint sonunda **demo edilebilir bir çıktı** olacak şekilde dağıtım yapılmıştır.

| Sprint | Tema | Hedef Puan |
|--------|------|-----------|
| Sprint 1 | Planlama & Proje Belirleme | ~100 SP |
| Sprint 2 | Üretim yeniden yapılandırması ve mobil teslim | 100 SP |
| Sprint 3 | Frontend tam yeniden yapılandırma + MVP tamamlama | ~100 SP |

---

## 🗂️ Epic'ler

| Epic | Açıklama |
|------|----------|
| **E0 — Planlama & Mimari** | Vizyon, teknoloji, kimlik ve gizlilik kararları |
| **E1 — Temel & Altyapı** | Flutter iskeleti, tema, cihaz DB, onboarding |
| **E2 — Harcama Yönetimi** | Manuel giriş, listeleme, kategori taksonomisi |
| **E3 — Fiş OCR** | Kamera/galeri, PaddleOCR, alan çıkarımı |
| **E4 — AI Koçluk (MakiKoç) & RAG** | Türkçe LLM koçu, güvenli istem ve kaynaklı tavsiye |
| **E5 — Kişisel Enflasyon & Tahmin** | Kişisel enflasyon, TÜİK karşılaştırma, Prophet |
| **E6 — Gamification & Orman** | Meydan okuma, XP/seviye, rozet, leaderboard, orman |
| **E7 — Bildirim Optimizasyonu** | LinTS ile anonim, kişiye özel bildirim |
| **E8 — Premium & Borç Simülatörü** | LightGBM borç simülasyonu, paywall |
| **E9 — Gizlilik & Güvenlik** | Cihazda veri, anonim sinyal, şifreleme |
| **E10 — Gözlemlenebilirlik & Teslim** | OpenTelemetry, güvenli loglar, kalite kapıları ve sürüm kanıtı |
| **E11 — Frontend Tam Yeniden Yapılandırma** | Mobil arayüz, gezinme, durum yönetimi ve erişilebilirlik |

---

## ✅ Sprint 2 Güncellenen Teslim Kapsamı

Sprint planlamasında temel ürün kapsamı korunmuş, üretim hazırlığı için teknik işler
ayrı kabul kriterleriyle görünür hâle getirilmiştir. Ayrıntılı kayıt:
[Sprint 2 Backlog](./Sprint-2/Sprint-2-Backlog.md).

| ID | İş | SP | Durum |
|----|----|----|-------|
| S2-01 | Mobil mimari, tasarım sistemi ve Türkçe arayüz | 8 | ✅ |
| S2-02 | Şifreli yerel veri ve güvenli oturum yönetimi | 8 | ✅ |
| S2-03 | Harcama yönetimi, kategoriler ve alan doğrulama | 8 | ✅ |
| S2-04 | Güvenli fiş OCR iş akışı | 8 | ✅ |
| S2-05 | Türkçe MakiKoç, RAG ve resmî kaynak kartları | 8 | ✅ |
| S2-06 | Para güvenli finans çekirdeği ve kişisel enflasyon | 13 | ✅ |
| S2-07 | Tahmin, geriye dönük sınama ve model seçimi | 8 | ✅ |
| S2-08 | Borç kapatma motoru ve tutarlı silme akışı | 8 | ✅ |
| S2-09 | Maki Ormanı, maskot ve uyarlanabilir ekranlar | 8 | ✅ |
| S2-10 | Pydantic v2 API sözleşmeleri ve güvenilir iş kuyruğu | 8 | ✅ |
| S2-11 | OpenTelemetry, kişisel veri temizleme ve alarmlar | 8 | ✅ |
| S2-12 | CI kalite kapıları, SBOM ve telefon APK kaydı | 5 | ✅ |
|  | **Toplam** | **100** | **✅** |

---

## 🏗️ Sprint 3 Öncelik Kararı

Sprint 3'ün birincil işi frontend'in tamamen yeniden yapılandırılmasıdır. Sprint 2'de
üretim seviyesine getirilen backend, API sözleşmeleri ve finans çekirdeği korunacak;
yeni mobil uygulama doğrudan bu katmanların üzerine bağlanacaktır.

| ID | İş | Öncelik | SP | Durum |
|----|----|----------|----|-------|
| S3-FE-01 | Frontend'i mimari ve görsel olarak tamamen yeniden yapılandırmak | 🔴 | 21 | ⏳ |

### S3-FE-01 Kabul Kriterleri

- Eski ekranlar üzerinde parça parça yama yapılmaz; gezinme, ekranlar, ortak
  bileşenler ve durum yönetimi yeniden kurulur.
- Sprint 2 backend'i ve `maki_finance_core` tek doğruluk kaynağı olarak kullanılır;
  paralel sahte finans mantığı yazılmaz.
- MakiKoç marka kimliği, maskot ve orman fikri korunur; bilgi mimarisi ve kullanıcı
  deneyimi yeniden tasarlanır.
- Kullanıcı metinleri, doğrulamalar ve hata mesajları tamamen Türkçedir.
- Dar ekran, büyük yazı ve klavye açık durumlarında piksel taşması oluşmaz.
- Erişilebilirlik, widget, görsel regresyon ve kritik uçtan uca akış testleri kalite
  kapısına eklenir.
- Yeni frontend özellik eşitliğine ulaşmadan eski uygulama kaldırılmaz.

---

## 📥 Detaylı Backlog (User Story'ler)

### E0 — Planlama & Mimari  · _Sprint 1_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-01 | Takım olarak problemi, hedef kitleyi ve değer önermesini netleştirmek istiyoruz ki doğru ürünü inşa edelim. | 🔴 | 8 | S1 |
| US-02 | Takım olarak ürün kimliği ve metafor kararını (MakiKoç + orman) vermek istiyoruz ki tutarlı bir deneyim tasarlayalım. | 🔴 | 8 | S1 |
| US-03 | Takım olarak teknoloji yığınını seçmek istiyoruz ki geliştirmeye net bir zeminle başlayalım. | 🔴 | 13 | S1 |
| US-04 | Takım olarak gizlilik mimarisini (cihazda veri / anonim sinyal) belirlemek istiyoruz ki gizlilik sözünü teknik olarak garanti edelim. | 🔴 | 13 | S1 |
| US-05 | Takım olarak kategori taksonomisi taslağını hazırlamak istiyoruz ki harcamalar tutarlı sınıflansın. | 🟡 | 5 | S1 |
| US-06 | Takım olarak 3 sprintlik takvim ve kapsamı belirlemek istiyoruz ki zamanı doğru yönetelim. | 🔴 | 8 | S1 |
| US-07 | Takım olarak riskleri tanımlamak istiyoruz ki erkenden önlem alalım. | 🟡 | 5 | S1 |

### E1 — Temel & Altyapı  · _Sprint 2_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-08 | Geliştirici olarak Flutter iskeleti ve klasör yapısını kurmak istiyorum ki geliştirmeye başlayabilelim. | 🔴 | 5 | S2 |
| US-09 | Geliştirici olarak tema + tasarım sistemi oluşturmak istiyorum ki tutarlı bir arayüz elde edelim. | 🟡 | 5 | S2 |
| US-10 | Geliştirici olarak cihaz DB şemasını (Isar/Drift) kurmak istiyorum ki veri offline saklansın. | 🔴 | 8 | S2 |
| US-11 | Kullanıcı olarak onboarding'de "Para ile ne yapmak istiyorsun?" akışını görmek istiyorum ki deneyim bana özel başlasın. | 🟡 | 5 | S2 |

### E2 — Harcama Yönetimi  · _Sprint 2_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-12 | Kullanıcı olarak manuel harcama ekleyip listeleyebilmek istiyorum ki harcamalarımı takip edeyim. | 🔴 | 8 | S2 |
| US-13 | Kullanıcı olarak harcamalarımı kategorilere göre görmek istiyorum ki nereye para gittiğini anlayayım. | 🟡 | 5 | S2 |

### E3 — Fiş OCR  · _Sprint 2_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-14 | Kullanıcı olarak fişi fotoğraflayıp otomatik harcama oluşturmak istiyorum ki elle girmekle uğraşmayayım. | 🔴 | 13 | S2 |
| US-15 | Kullanıcı olarak OCR sonrası çıkan bilgiyi düzenleyip onaylamak istiyorum ki hatalar düzeltilebilsin. | 🟡 | 5 | S2 |

### E4 — AI Koçluk (MakiKoç) & RAG  · _Sprint 2–3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-16 | Kullanıcı olarak Türkçe bir finans koçuyla konuşmak istiyorum ki kişisel tavsiye alayım. | 🔴 | 8 | S2 |
| US-17 | Kullanıcı olarak koçun tavsiyelerini TÜİK/Merkez Bankası kaynaklarıyla göstermesini istiyorum ki güvenilir olsun. | 🔴 | 13 | S2→S3 |
| US-18 | Kullanıcı olarak günlük/haftalık kısa koçluk seansı görmek istiyorum ki düzenli rehberlik alayım. | 🟡 | 5 | S3 |

### E5 — Kişisel Enflasyon & Tahmin  · _Sprint 3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-19 | Kullanıcı olarak kendi enflasyonumu TÜİK ile karşılaştıran grafik görmek istiyorum ki gerçek durumumu anlayayım. | 🔴 | 8 | S3 |
| US-20 | Kullanıcı olarak gelecek harcama tahminimi (Prophet) görmek istiyorum ki bütçe planlayayım. | 🟡 | 5 | S3 |

### E6 — Gamification & Orman  · _Sprint 3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-21 | Kullanıcı olarak masum günlük meydan okumalar almak istiyorum ki motive olayım. | 🟡 | 5 | S3 |
| US-22 | Kullanıcı olarak XP/seviye ve rozet kazanmak istiyorum ki ilerlememi hissedeyim. | 🟡 | 5 | S3 |
| US-23 | Kullanıcı olarak meydan okuma tamamladıkça orman/fidan ilerlemesi görmek istiyorum ki görsel geri bildirim alayım. | 🟢 | 5 | S3 |
| US-24 | Kullanıcı olarak yüzde bazlı kimliksiz leaderboard görmek istiyorum ki gizliliğim korunarak yarışayım. | 🟢 | 5 | S3 |

### E7 — Bildirim Optimizasyonu  · _Sprint 3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-25 | Kullanıcı olarak bana en uygun zamanda bildirim almak istiyorum ki rahatsız olmadan hatırlatılayım. (LinTS, yalnızca anonim özellikler) | 🟢 | 8 | S3 |

### E8 — Premium & Borç Simülatörü  · _Sprint 3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-26 | Kullanıcı olarak sanal borç simülatörüyle borçtan çıkma planı görmek istiyorum ki hedef koyayım. (LightGBM, Premium) | 🟡 | 8 | S3 |
| US-27 | Kullanıcı olarak premium özelliklere paywall'dan erişmek istiyorum ki uygulama sürdürülebilir olsun. | 🟢 | 5 | S3 |

### E9 — Gizlilik & Güvenlik  · _Sürekli_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| US-28 | Kullanıcı olarak tüm finans verimin cihazımda kalacağından emin olmak istiyorum ki gizliliğim korunsun. | 🔴 | 8 | S2–S3 |
| US-29 | Kullanıcı olarak sunucuya yalnızca anonim sinyal gittiğini bilmek istiyorum ki güven duyayım. | 🔴 | 5 | S3 |

### E11 — Frontend Tam Yeniden Yapılandırma  · _Sprint 3_

| ID | User Story | Öncelik | SP | Sprint |
|----|-----------|---------|----|--------|
| S3-FE-01 | Kullanıcı olarak sade, hızlı, erişilebilir ve tutarlı bir mobil deneyim istiyorum ki finansal durumumu ekranda kaybolmadan yönetebileyim. | 🔴 | 21 | S3 |

---

## 📌 Öncelik Sıralaması (İlk 10 — MVP Kritik)

1. US-01, US-03, US-04 — Vizyon, teknoloji, gizlilik (S1)
2. US-08, US-10 — İskelet + cihaz DB (S2)
3. US-12 — Manuel harcama (S2)
4. US-14 — Fiş OCR (S2)
5. US-16, US-17 — AI koç + kaynaklandırma (S2→S3)
6. S3-FE-01 — Frontend tam yeniden yapılandırma (S3)
7. US-19 — Kişisel enflasyon (S3)
8. US-28 — Cihazda veri garantisi (S2–S3)
