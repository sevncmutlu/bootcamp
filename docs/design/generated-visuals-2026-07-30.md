# MakiKoç görsel üretim kaydı

Tarih: 30 Temmuz 2026

## Sanat yönü

Finansal ilerleme, yerel bir ekosistemin büyümesi olarak ele alındı. Ana imza,
finansal yolun ağaç halkalarına dönüşmesi. Görsel dil; derin Maki yeşili, yosun,
zeytin, parşömen ve ölçülü kehribar renklerinden oluşuyor. Jenerik para, banka,
coin veya fintech ikonografisi özellikle kullanılmadı.

Görseller yerleşik ImageGen ile üretildi; uygulamaya kayıplı kalite 88 WebP
olarak eklendi. Yüksek çözünürlüklü PNG kaynaklar teslim klasöründe korunuyor.

## Üretilen varlıklar

### Finansal orman

- Mod: `stylized-concept`
- Uygulama yolu: `frontend/assets/images/maki_financial_forest_v3.webp`
- Kullanım: Orman ilerleme kartı
- Kaynak boyut: 1586 × 992 px
- Prompt özeti: Anadolu/Akdeniz ormanı, genç Kermes Meşesi, ağaç halkalarına
  dönüşen kehribar yol, gün doğumu, arayüz metni ve maskot için güvenli alan.

### Yerel flora atlası

- Mod: `scientific-educational`
- Uygulama yolu: `frontend/assets/images/maki_flora_atlas_v1.webp`
- Kullanım: Orman ekranındaki hedef/tür kataloğu
- Kaynak boyut: 1693 × 929 px
- Prompt özeti: Parşömen üzerinde ayrı ve etiketsiz Mersin, Karayemiş, Kermes
  Meşesi, Ilgın ve Funda + Katırtırnağı botanik örnekleri.

### Maki onboarding koruluğu

- Mod: `illustration-story`
- Referans: mevcut Maki karakter kimliği ve yeşil kapüşonlu kostüm
- Uygulama yolu: `frontend/assets/images/maki_onboarding_grove_v1.webp`
- Kullanım: Onboarding açılış kahraman görseli
- Kaynak boyut: 1086 × 1448 px
- Prompt özeti: Maki ve yeni dikilmiş Kermes Meşesi, ilk finansal adımı anlatan
  taş yol, Anadolu/Akdeniz bitkileri ve sakin gün doğumu.

### Yaşayan Maki koruluğu

- Mod: `stylized-concept`
- Referans: mevcut Maki karakter kimliği ve onboarding koruluğunun 3D sanat dili
- Uygulama yolu: `frontend/assets/images/maki_living_grove_v1.webp`
- Kullanım: Amaca özel orman kahraman sahnesi ve beş aşamalı büyüme yolu
- Prompt özeti: Maki'nin yeşil kapüşonlu kimliğini koruyan geniş 16:9 yaşayan
  Anadolu/Akdeniz koruluğu; Mersin, Karayemiş, Kermes Meşesi, Ilgın ve çalı
  kümeleri; ağaç halkalarına dönüşen patika, sakin gün doğumu ve arayüz metni
  için güvenli koyu alan.

## Uygulama ayrıntıları

- Görsellerde metin yok; bütün metinler Flutter katmanında yerelleştiriliyor.
- Görseller `Semantics` açıklamalarıyla Türkçe ve İngilizce erişilebilir.
- Kırpmalar kritik karakter ve bitki detaylarını koruyacak şekilde ayarlandı.
- `flutter analyze --no-pub` temiz, 98 Flutter testi geçti.
- `scripts/check_frontend_boundary.ps1` doğrulandı.
