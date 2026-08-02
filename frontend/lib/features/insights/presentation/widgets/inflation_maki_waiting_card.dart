part of '../pages/inflation_screen.dart';

/// Honest empty-data preview of the exportable result card. It keeps the 3D
/// Maki experience visible without inventing an inflation value.
class InflationMakiWaitingCard extends StatelessWidget {
  const InflationMakiWaitingCard({
    super.key,
    this.status = 'insufficient_data',
    this.coveragePercent,
  });

  final String status;
  final double? coveragePercent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    const accent = Color(0xFF8E5360);
    const surface = Color(0xFFF8EAEC);

    final mascot = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/mascot/maki_concerned_v1.png',
        key: const ValueKey('inflation-maki-waiting'),
        width: 148,
        height: 148,
        fit: BoxFit.cover,
      ),
    );
    final statusText = switch (status) {
      'needs_second_price' =>
        isTurkish
            ? 'Aynı ürünün ikinci tarihli fiyatını eklediğinde gerçek değişimi hesaplayacağım.'
            : 'Add a second dated price for the same product to calculate its real change.',
      'insufficient_coverage' =>
        isTurkish
            ? 'Sepet kapsamın ${coveragePercent?.toStringAsFixed(0) ?? '0'}%. Sonuç için en az %70 kapsam gerekiyor.'
            : 'Basket coverage is ${coveragePercent?.toStringAsFixed(0) ?? '0'}%. At least 70% is required.',
      _ =>
        isTurkish
            ? 'İlk ürün fiyatını ekle; aynı ürünü daha sonra yeniden kaydettiğinde değişimi ölçelim.'
            : 'Add your first product price, then record it again later to measure the change.',
    };
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTurkish ? 'ÖRNEK · VERİ BEKLENİYOR' : 'PREVIEW · WAITING FOR DATA',
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isTurkish
              ? 'Maki karşılaştırmaya hazırlanıyor'
              : 'Maki is getting ready',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF3C2730),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 11),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InflationMetric(label: 'Senin sepetin', value: '—', color: accent),
            _InflationMetric(
              label: 'Karşılaştırma',
              value: '—',
              color: Color(0xFF685C61),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          statusText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF5C444C),
            height: 1.42,
          ),
        ),
      ],
    );

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: .22)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, surface],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.center, child: mascot),
                  const SizedBox(height: 18),
                  content,
                ],
              );
            }
            return Row(
              children: [
                mascot,
                const SizedBox(width: 22),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }
}
