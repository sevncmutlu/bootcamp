part of '../pages/inflation_screen.dart';

/// A privacy-safe, image-ready summary of the user's personal inflation.
/// Transaction rows and category amounts intentionally stay outside the
/// repaint boundary, so they can never leak into the exported PNG.
class InflationMakiShareCard extends StatefulWidget {
  const InflationMakiShareCard({
    super.key,
    required this.personalInflation,
    this.officialInflation,
    this.basePeriod,
    this.currentPeriod,
  });

  final double personalInflation;
  final double? officialInflation;
  final String? basePeriod;
  final String? currentPeriod;

  @override
  State<InflationMakiShareCard> createState() => _InflationMakiShareCardState();
}

class _InflationMakiShareCardState extends State<InflationMakiShareCard> {
  final GlobalKey _captureKey = GlobalKey();
  bool _busy = false;

  bool get _hasComparison => widget.officialInflation != null;

  bool get _isEncouraging =>
      !_hasComparison || widget.personalInflation <= widget.officialInflation!;

  double get _difference =>
      (widget.personalInflation - widget.officialInflation!).abs();

  String _percent(BuildContext context, double value) {
    final valueText = value
        .toStringAsFixed(1)
        .replaceFirst(
          '.',
          Localizations.localeOf(context).languageCode == 'tr' ? ',' : '.',
        );
    return Localizations.localeOf(context).languageCode == 'tr'
        ? '%$valueText'
        : '$valueText%';
  }

  Future<Uint8List> _capturePng() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Inflation card is not ready to export.');
    }

    final width = boundary.size.width;
    final pixelRatio = (1600 / width).clamp(1.5, 3.0).toDouble();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Inflation card could not be rendered.');
    }
    return byteData.buffer.asUint8List();
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await _capturePng();
      await PublicFileSaver().saveBytes(
        bytes: bytes,
        fileName: 'maki-kisisel-enflasyon.png',
        mimeType: 'image/png',
        subDir: 'Maki',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maki kartın PNG olarak indirildi.')),
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
          fileNameOverrides: const ['maki-kisisel-enflasyon.png'],
          title: 'Maki kişisel enflasyon kartı',
          text:
              'Kişisel enflasyon özetim — Maki ile finans ormanımı büyütüyorum.',
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

    final headline = !_hasComparison
        ? (isTurkish ? 'Sepet değişimin hazır' : 'Your basket change is ready')
        : positive
        ? (isTurkish
              ? 'Tebrikler, ritmin dengeli'
              : 'Well done, your pace is balanced')
        : (isTurkish
              ? 'Birlikte biraz dikkat edelim'
              : 'Let’s pay a little more attention');
    final comparison = !_hasComparison
        ? (isTurkish
              ? 'Kişisel sonuç gerçek fiyat geçmişinden hesaplandı. Resmî karşılaştırma çevrimdışıyken sahte değer göstermiyorum.'
              : 'Your result uses real price history. No comparison is invented while official data is offline.')
        : positive
        ? (isTurkish
              ? 'Kişisel sepetindeki fiyat artışı karşılaştırma oranının ${_percent(context, _difference)} puan altında.'
              : 'Your basket increase is ${_percent(context, _difference)} points below the comparison rate.')
        : (isTurkish
              ? 'Kişisel sepetindeki fiyat artışı karşılaştırma oranının ${_percent(context, _difference)} puan üzerinde.'
              : 'Your basket increase is ${_percent(context, _difference)} points above the comparison rate.');

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
                          : 'assets/mascot/maki_concerned_v1.png',
                      key: ValueKey(
                        positive
                            ? 'inflation-maki-proud'
                            : 'inflation-maki-concerned',
                      ),
                      width: compact ? 132 : 170,
                      height: compact ? 132 : 170,
                      fit: BoxFit.cover,
                    ),
                  );
                  final content = Expanded(
                    child: Column(
                      crossAxisAlignment: compact
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAKİ · KİŞİSEL ENFLASYON',
                          textAlign: compact
                              ? TextAlign.center
                              : TextAlign.left,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          headline,
                          textAlign: compact
                              ? TextAlign.center
                              : TextAlign.left,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF18352B),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: compact
                              ? WrapAlignment.center
                              : WrapAlignment.start,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _InflationMetric(
                              label: isTurkish
                                  ? 'Senin sepetin'
                                  : 'Your basket',
                              value: _percent(
                                context,
                                widget.personalInflation,
                              ),
                              color: accent,
                            ),
                            _InflationMetric(
                              label: isTurkish ? 'Karşılaştırma' : 'Comparison',
                              value: widget.officialInflation == null
                                  ? (isTurkish ? 'Çevrimdışı' : 'Offline')
                                  : _percent(
                                      context,
                                      widget.officialInflation!,
                                    ),
                              color: const Color(0xFF54655E),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          comparison,
                          textAlign: compact
                              ? TextAlign.center
                              : TextAlign.left,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF334B42),
                            height: 1.42,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );

                  return Column(
                    children: [
                      if (compact) ...[
                        mascot,
                        const SizedBox(height: 18),
                        Row(children: [content]),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            mascot,
                            const SizedBox(width: 24),
                            content,
                          ],
                        ),
                      const SizedBox(height: 18),
                      Divider(color: accent.withValues(alpha: 0.18)),
                      const SizedBox(height: 8),
                      Text(
                        isTurkish
                            ? 'Dönem: ${widget.basePeriod ?? '—'} → ${widget.currentPeriod ?? '—'} · Bu sonuç kendi kayıtlı sepetine dayanır; resmî TÜFE değildir.'
                            : 'Period: ${widget.basePeriod ?? '—'} → ${widget.currentPeriod ?? '—'} · This result is based on your recorded basket; it is not official CPI.',
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
