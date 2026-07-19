# Finans çekirdeği entegrasyonu

Paket saf Dart çalışır. Flutter, ağ veya veritabanı bağımlılığı taşımaz. Sevinç'in ekran katmanı
yalnızca `package:maki_finance_core/maki_finance_core.dart` giriş noktasını kullanmalıdır.

## Para ve borç

Para `double` ile tutulmaz. TRY için bir lira `100` alt para birimidir.

```dart
const tryCurrency = Currency('TRY');
const engine = DebtEngine();

final result = engine.simulate(
  DebtScenario(
    debts: [
      DebtAccount(
        id: 'kart-1',
        balance: const Money(
          minorUnits: 125000,
          currency: tryCurrency,
        ),
        annualRate: const AnnualRate(basisPoints: 4200),
        minimumPayment: const Money(
          minorUnits: 10000,
          currency: tryCurrency,
        ),
      ),
    ],
    monthlyBudget: const Money(
      minorUnits: 25000,
      currency: tryCurrency,
    ),
    strategy: DebtStrategy.avalanche,
    maxMonths: 360,
  ),
);
```

`status` alanı kapanma, yetersiz asgari bütçe, negatif amortisman veya süre aşımı durumunu açıkça
taşır. Başarısız durumlar kapanmış gibi ay sayısı üretmez.

## Kişisel enflasyon

```dart
final result = LaspeyresIndex.calculate([
  BasketItem(
    id: 'sut',
    categoryId: 'market',
    baseUnitPrice: const Money(
      minorUnits: 3000,
      currency: Currency('TRY'),
    ),
    currentUnitPrice: const Money(
      minorUnits: 3600,
      currency: Currency('TRY'),
    ),
    baseQuantity: 4,
    match: BasketMatch.matched,
  ),
]);
```

Endeks ve katkılar baz puan döner. Kapsama `7000` altındaysa sonuç
`InflationStatus.insufficientCoverage` olur. Dışlanan kalemler kapsama paydasında kalır fakat fiyat
endeksine girmez.

## İmzalı LightGBM modeli

Model dosyası yalnızca şu sıra tamamlanırsa yüklenir:

1. Manifest alanları ve şema sürümü doğrulanır.
2. Kanonik manifest gövdesinin Ed25519 imzası doğrulanır.
3. Model dosyasının SHA-256 özeti manifestle karşılaştırılır.
4. Özellik adları ve sırası LightGBM dosyasıyla eşleştirilir.
5. Sürüm 2 manifestteki Platt veya isotonic kalibrasyon ham skora uygulanır.

```dart
final model = await VerifiedLightGbmModel.load(
  modelBytes: modelBytes,
  manifestBytes: manifestBytes,
  publicKey: embeddedPublicKey,
);

final probability = model.predictProbability([
  normalizedIncome,
  debtRatio,
  spendingVolatility,
]);
```

İmzasız, değiştirilmiş veya sözleşme dışı model için çıkarım yapılmaz. Özel anahtar uygulamaya
konmaz; yalnızca yayın doğrulama anahtarı uygulamaya gömülür.

Üretim manifesti veri özeti, ikili amaç, kalibrasyon ve maliyet matrisinden gelen karar eşiğini de
imzalı gövdede taşır. Sürüm 1 modeller geriye uyumlu olarak kalibrasyonsuz çalışır.

## LinTS kararı ve ödülü

```dart
final policy = LinTsPolicy(
  state: restoredState,
  gaussianSource: secureGaussianSource,
  clock: deviceClock,
);

final decision = policy.decide(context);
await stateStore.save(policy.state.toJson());

final applied = policy.reward(
  decisionId: decision.decisionId,
  context: decision.context,
  reward: 1,
);
await stateStore.save(policy.state.toJson());
```

Karar durumu ödülden önce kalıcılaştırılır. Aynı karar ve ödül ikinci kez matrisi değiştirmez.
Farklı bağlam veya farklı ödülle tekrar deneme sözleşme hatasıdır.

## Hata sınırları

- Para birimi uyuşmazlığı `CurrencyMismatch` üretir.
- Geçersiz alan girdileri Türkçe `ArgumentError` veya alan sözleşmesi hatası üretir.
- Finans hesapları durum değerleriyle, güvenlik ihlalleri istisnayla döner.
- Model imza ve özet hataları güvenli biçimde kapanır; eski veya doğrulanmamış modele düşülmez.
- Günlüklere ham finans değeri, kullanıcı kimliği, belge içeriği veya özellik vektörü yazılmaz.
