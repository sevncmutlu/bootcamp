part of '../pages/inflation_screen.dart';

/// Privacy-safe, exportable summary of the user's monthly spending change and
/// current cash-flow pressure. Raw transaction rows never enter this boundary.
class InflationMakiShareCard extends StatefulWidget {
  const InflationMakiShareCard({
    super.key,
    required this.personalSpendingChange,
    required this.currentIncome,
    required this.currentExpenses,
    required this.debtPayments,
    required this.netCashFlow,
    required this.financialPressure,
    required this.status,
    required this.currentTransactionCount,
    required this.previousTransactionCount,
    this.officialInflation,
    this.basePeriod,
    this.currentPeriod,
  });

  final double? personalSpendingChange;
  final double? officialInflation;
  final double currentIncome;
  final double currentExpenses;
  final double debtPayments;
  final double netCashFlow;
  final double? financialPressure;
  final String status;
  final int currentTransactionCount;
  final int previousTransactionCount;
  final String? basePeriod;
  final String? currentPeriod;

  @override
  State<InflationMakiShareCard> createState() => _InflationMakiShareCardState();
}

class _InflationMakiShareCardState extends State<InflationMakiShareCard> {
  final GlobalKey _captureKey = GlobalKey();
  bool _busy = false;

  bool get _hasComparison =>
      widget.personalSpendingChange != null && widget.officialInflation != null;

  bool get _isEncouraging {
    final pressureIsHealthy =
        widget.financialPressure != null && widget.financialPressure! < 60;
    final trendIsHealthy =
        !_hasComparison ||
        widget.personalSpendingChange! <= widget.officialInflation!;
    return pressureIsHealthy && trendIsHealthy;
  }

  double? get _difference => !_hasComparison
      ? null
      : (widget.personalSpendingChange! - widget.officialInflation!).abs();

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      await PublicFileSaver().saveBytes(
        bytes: bytes,
        fileName: 'maki-kisisel-finans-ozeti.png',
        mimeType: 'image/png',
        subDir: 'Maki',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maki finans özeti PNG olarak indirildi.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görsel indirilemedi. Lütfen yeniden dene.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      if (!mounted) return;
      final renderBox = context.findRenderObject();
      final origin = renderBox is RenderBox
          ? renderBox.localToGlobal(Offset.zero) & renderBox.size
          : null;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png')],
          fileNameOverrides: const ['maki-kisisel-finans-ozeti.png'],
          title: 'Maki kişisel finans özeti',
          text:
              'Aylık harcama değişimimi ve finans ritmimi Maki ile izliyorum.',
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paylaşım açılamadı. Görseli indirip paylaşabilirsin.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    final positive = _isEncouraging;
    final accent = positive ? const Color(0xFF1F7651) : const Color(0xFFA64654);
    final softAccent = positive
        ? const Color(0xFFE5F2E8)
        : const Color(0xFFF9E7E8);
    final hasPersonal = widget.personalSpendingChange != null;

    final headline = widget.financialPressure == null
        ? (isTurkish
              ? 'Gelir kaydını bekliyorum'
              : 'Waiting for an income record')
        : positive
        ? (isTurkish
              ? 'Tebrikler, bütçen dengeli'
              : 'Well done, your budget is balanced')
        : (isTurkish
              ? 'Birlikte biraz dikkat edelim'
              : 'Let’s pay a little more attention');
    final comparison = _comparisonText(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTurkish
              ? 'MAKİ · KİŞİSEL FİNANS ÖZETİ'
              : 'MAKI · PERSONAL FINANCE SUMMARY',
          style: theme.textTheme.labelMedium?.copyWith(
            color: accent,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          headline,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF18352B),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _InflationMetric(
              label: isTurkish ? 'Harcama değişimin' : 'Spending change',
              value: hasPersonal
                  ? _percent(context, widget.personalSpendingChange!)
                  : (isTurkish ? 'Veri birikiyor' : 'Collecting data'),
              color: accent,
            ),
            _InflationMetric(
              label: isTurkish ? 'TÜİK aylık' : 'Monthly TÜİK',
              value: widget.officialInflation == null
                  ? (isTurkish ? 'Çevrimdışı' : 'Offline')
                  : _percent(context, widget.officialInflation!),
              color: const Color(0xFF54655E),
            ),
            _InflationMetric(
              label: isTurkish ? 'Finans baskısı' : 'Finance pressure',
              value: widget.financialPressure == null
                  ? '—'
                  : '${widget.financialPressure!.round()}/100',
              color: accent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          comparison,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF334B42),
            height: 1.42,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RepaintBoundary(
          key: _captureKey,
          child: Material(
            color: softAccent,
            borderRadius: BorderRadius.circular(28),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: accent.withValues(alpha: 0.22)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, softAccent],
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 560;
                  final mascot = ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      positive
                          ? 'assets/mascot/maki_proud_v1.png'
                          : 'assets/mascot/maki_concerned_transparent.png',
                      key: ValueKey(
                        positive
                            ? 'inflation-maki-proud'
                            : 'inflation-maki-concerned',
                      ),
                      width: compact ? 132 : 170,
                      height: compact ? 132 : 170,
                      fit: BoxFit.contain,
                    ),
                  );
                  return Column(
                    children: [
                      if (compact) ...[
                        mascot,
                        const SizedBox(height: 18),
                        content,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            mascot,
                            const SizedBox(width: 24),
                            Expanded(child: content),
                          ],
                        ),
                      const SizedBox(height: 18),
                      Divider(color: accent.withValues(alpha: 0.18)),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InflationMetric(
                            label: isTurkish ? 'Gelir' : 'Income',
                            value: _money(context, widget.currentIncome),
                            color: const Color(0xFF1F7651),
                          ),
                          _InflationMetric(
                            label: isTurkish ? 'Gider' : 'Expenses',
                            value: _money(context, widget.currentExpenses),
                            color: const Color(0xFFA64654),
                          ),
                          _InflationMetric(
                            label: isTurkish ? 'Borç ödemesi' : 'Debt payments',
                            value: _money(context, widget.debtPayments),
                            color: const Color(0xFF7A5A24),
                          ),
                          _InflationMetric(
                            label: isTurkish ? 'Net nakit' : 'Net cash',
                            value: _money(context, widget.netCashFlow),
                            color: widget.netCashFlow >= 0
                                ? const Color(0xFF1F7651)
                                : const Color(0xFFA64654),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isTurkish
                            ? 'Dönem: ${widget.basePeriod ?? '—'} → ${widget.currentPeriod ?? '—'} · Harcama değişimi kişisel kayıtlarına dayanır; resmî TÜFE değildir.'
                            : 'Period: ${widget.basePeriod ?? '—'} → ${widget.currentPeriod ?? '—'} · Spending change uses your records and is not official CPI.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF5B6E66),
                          height: 1.35,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('download-inflation-card'),
                onPressed: _busy ? null : _download,
                icon: const Icon(Icons.download_rounded),
                label: Text(isTurkish ? 'PNG indir' : 'Download PNG'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('share-inflation-card'),
                onPressed: _busy ? null : _share,
                icon: _busy
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(isTurkish ? 'Paylaş' : 'Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
