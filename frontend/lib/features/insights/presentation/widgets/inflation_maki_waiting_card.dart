part of '../pages/inflation_screen.dart';

class InflationMakiWaitingCard extends StatelessWidget {
  const InflationMakiWaitingCard({
    super.key,
    this.status = 'insufficient_history',
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
    final statusText = status == 'missing_income'
        ? (isTurkish
              ? 'Bir gelir kaydı eklediğinde gider ve borç yükünün bütçene etkisini hesaplayacağım.'
              : 'Add an income record to calculate how expenses and debt payments affect your budget.')
        : (isTurkish
              ? 'Karşılaştırma için son iki 30 günlük dönemde en az üçer tüketim gideri gerekiyor.'
              : 'A comparison needs at least three consumption expenses in each 30-day period.');

    final mascot = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/mascot/maki_concerned_transparent.png',
        key: const ValueKey('inflation-maki-waiting'),
        width: 148,
        height: 148,
        fit: BoxFit.contain,
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTurkish ? 'VERİ BİRİKİYOR' : 'COLLECTING DATA',
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.05,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          isTurkish
              ? 'Maki finans ritmini öğreniyor'
              : 'Maki is learning your financial rhythm',
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
            _InflationMetric(
              label: 'Harcama değişimi',
              value: '—',
              color: accent,
            ),
            _InflationMetric(
              label: 'TÜİK karşılaştırması',
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
