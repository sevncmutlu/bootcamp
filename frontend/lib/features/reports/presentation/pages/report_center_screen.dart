import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/utils/currency.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/reports/data/maki_pdf_report_service.dart';
import 'package:public_file_saver/public_file_saver.dart';
import 'package:share_plus/share_plus.dart';

@visibleForTesting
Future<PublicSavedFile?> saveMakiReportPdf({
  required Uint8List bytes,
  required String fileName,
  PublicFileSaver? saver,
  bool? useSaveDialog,
}) {
  final fileSaver = saver ?? PublicFileSaver();
  final shouldUseSaveDialog =
      useSaveDialog ??
      (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  if (shouldUseSaveDialog) {
    return fileSaver.saveBytesWithDialog(
      bytes: bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );
  }

  return fileSaver.saveBytes(
    bytes: bytes,
    fileName: fileName,
    mimeType: 'application/pdf',
    subDir: 'Maki',
  );
}

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key});

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  late final MakiPdfReportService _service;
  MakiReportPeriod _period = MakiReportPeriod.weekly;
  DateTime _anchor = DateTime.now();
  bool _hideAmounts = false;
  bool _includeTransactions = true;
  bool _busy = false;
  MakiReportSnapshot? _snapshot;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _service = MakiPdfReportService(AppDatabase.instance);
    _reloadPreview();
  }

  Future<void> _reloadPreview() async {
    final snapshot = await _service.loadSnapshot(
      period: _period,
      anchor: _anchor,
    );
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _pdfBytes = null;
    });
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (selected == null || !mounted) return;
    setState(() => _anchor = selected);
    await _reloadPreview();
  }

  Future<void> _generate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final snapshot = await _service.loadSnapshot(
        period: _period,
        anchor: _anchor,
      );
      final bytes = await _service.buildPdf(
        snapshot: snapshot,
        hideAmounts: _hideAmounts,
        includeTransactions: _includeTransactions,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _pdfBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maki raporun cihazında hazırlandı.')),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF hazırlanamadı. Lütfen yeniden dene.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _fileName {
    final date = DateFormat('yyyy-MM-dd').format(_anchor);
    return 'makikoc-${_period.name}-$date.pdf';
  }

  Future<void> _download() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    try {
      final savedFile = await saveMakiReportPdf(
        bytes: bytes,
        fileName: _fileName,
      );
      if (!mounted) return;
      if (savedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF kaydetme iptal edildi.')),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF cihaza kaydedildi.')));
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF kaydedilemedi.')));
    }
  }

  Future<void> _share() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    try {
      final box = context.findRenderObject();
      final origin = box is RenderBox
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'application/pdf', name: _fileName)],
        subject: 'MakiKoç finans raporu',
        text: 'MakiKoç ile hazırladığım cihaz içi finans raporu.',
        sharePositionOrigin: origin,
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım ekranı açılamadı.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const MakiAppBarTitle(title: 'Raporlarım')),
      body: MakiBackground(
        maxContentWidth: 780,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/mascot/maki_proud_v1.png',
                      width: 82,
                      height: 82,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Finans ormanın, tek bir raporda',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'MakiDisplay',
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          const Text(
                            'Gelir ve giderlerin yalnızca bu cihazda işlenir. PDF oluşturulurken finans verin sunucuya gönderilmez.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Rapor dönemi', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<MakiReportPeriod>(
              segments: const [
                ButtonSegment(
                  value: MakiReportPeriod.daily,
                  label: Text('Günlük'),
                  icon: Icon(Icons.today_rounded),
                ),
                ButtonSegment(
                  value: MakiReportPeriod.weekly,
                  label: Text('Haftalık'),
                  icon: Icon(Icons.view_week_outlined),
                ),
                ButtonSegment(
                  value: MakiReportPeriod.monthly,
                  label: Text('Aylık'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {_period},
              onSelectionChanged: (selection) async {
                setState(() => _period = selection.first);
                await _reloadPreview();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              leading: const Icon(Icons.event_outlined),
              title: const Text('Referans tarihi'),
              subtitle: Text(
                DateFormat('d MMMM yyyy', 'tr_TR').format(_anchor),
              ),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    value: _hideAmounts,
                    onChanged: (value) => setState(() {
                      _hideAmounts = value;
                      _pdfBytes = null;
                    }),
                    secondary: const Icon(Icons.visibility_off_outlined),
                    title: const Text('Tutarları gizle'),
                    subtitle: const Text(
                      'Paylaşılabilir raporda rakamları maskeler.',
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile.adaptive(
                    value: _includeTransactions,
                    onChanged: (value) => setState(() {
                      _includeTransactions = value;
                      _pdfBytes = null;
                    }),
                    secondary: const Icon(Icons.receipt_long_outlined),
                    title: const Text('İşlemleri ekle'),
                    subtitle: const Text(
                      'Gelir ve gider dökümünü PDF’ye dahil eder.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (snapshot != null)
              _ReportPreview(snapshot: snapshot, hideAmounts: _hideAmounts),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _busy ? null : _generate,
              icon: _busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_busy ? 'Hazırlanıyor…' : 'PDF’yi cihazda hazırla'),
            ),
            if (_pdfBytes != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _download,
                      icon: const Icon(Icons.save_alt_rounded),
                      label: Text(
                        !kIsWeb &&
                                defaultTargetPlatform == TargetPlatform.android
                            ? 'Farklı kaydet'
                            : 'İndir',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Paylaş'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview({required this.snapshot, required this.hideAmounts});

  final MakiReportSnapshot snapshot;
  final bool hideAmounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String amount(double value) =>
        hideAmounts ? '•••• TL' : formatTL(value, context: context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Canlı önizleme', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _PreviewMetric('Gelir', amount(snapshot.totalIncome)),
                ),
                Expanded(
                  child: _PreviewMetric('Gider', amount(snapshot.totalExpense)),
                ),
                Expanded(child: _PreviewMetric('Net', amount(snapshot.net))),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${snapshot.incomes.length + snapshot.expenses.length} işlem · ${snapshot.categoryTotals.length} gider kategorisi',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
    ],
  );
}
