# MakiKoç Maskot Görselleri

Bu klasör, marka rehberindeki **POZ KÜTÜPHANESİ** ginepig çizimlerini mobil
kullanıma uygun, kayıpsız WebP dosyaları olarak barındırır.
`lib/widgets/mascot.dart` bu dosyaları poz → dosya eşlemesiyle yükler.

Beklenen dosyalar:

| MascotPose | Görseldeki poz            | Dosya                |
|------------|---------------------------|----------------------|
| `wave`     | Merhaba (el sallama)      | `maki_wave.webp`      |
| `thinking` | Düşünüyorum               | `maki_thinking.webp`  |
| `celebrate`| Kutluyorum                | `maki_celebrate.webp` |
| `happy`    | Motivasyon / hedefe ulaş  | `maki_happy.webp`     |
| `neutral`  | Ön görünüş (nötr)         | `maki_neutral.webp`   |
| `sleeping` | Kahve molası (dinlenme)   | `maki_sleeping.webp`  |
| avatar     | Nötr baş (küçük avatar)   | `maki_avatar.webp`    |

Bir görsel yüklenemezse `mascot.dart` basit ginepig yüzü çizerek uygulamanın
çalışmaya devam etmesini sağlar.
