import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:maki_app/core/database/database.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum MakiReportPeriod { daily, weekly, monthly }

final class MakiReportSnapshot {
  const MakiReportSnapshot({
    required this.period,
    required this.start,
    required this.endExclusive,
    required this.expenses,
    required this.incomes,
  });

  final MakiReportPeriod period;
  final DateTime start;
  final DateTime endExclusive;
  final List<Expense> expenses;
  final List<Income> incomes;

  double get totalExpense => expenses.fold(0, (sum, item) => sum + item.amount);
  double get totalIncome => incomes.fold(0, (sum, item) => sum + item.amount);
  double get net => totalIncome - totalExpense;

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }
}

final class MakiPdfReportService {
  const MakiPdfReportService(this._database);

  final AppDatabase _database;

  Future<MakiReportSnapshot> loadSnapshot({
    required MakiReportPeriod period,
    required DateTime anchor,
  }) async {
    final range = _range(period, anchor);
    final results = await Future.wait<Object>([
      _database.getAllExpenses(),
      _database.getAllIncomes(),
    ]);
    final expenses = (results[0] as List<Expense>)
        .where((item) => _contains(item.date, range.$1, range.$2))
        .toList(growable: false);
    final incomes = (results[1] as List<Income>)
        .where((item) => _contains(item.date, range.$1, range.$2))
        .toList(growable: false);
    return MakiReportSnapshot(
      period: period,
      start: range.$1,
      endExclusive: range.$2,
      expenses: expenses,
      incomes: incomes,
    );
  }

  Future<Uint8List> buildPdf({
    required MakiReportSnapshot snapshot,
    required bool hideAmounts,
    required bool includeTransactions,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/MakiSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/MakiSans-Bold.ttf'),
    );
    final maki = pw.MemoryImage(
      (await rootBundle.load(
        'assets/mascot/maki_proud_v1.png',
      )).buffer.asUint8List(),
    );
    final document = pw.Document(
      title: 'MakiKoç ${periodLabel(snapshot.period)} raporu',
      author: 'MakiKoç',
      creator: 'MakiKoç cihaz içi rapor merkezi',
    );
    final green = PdfColor.fromHex('#174E3C');
    final dark = PdfColor.fromHex('#102B23');
    final cream = PdfColor.fromHex('#F5F0E4');
    final sage = PdfColor.fromHex('#DDEBDD');
    final coral = PdfColor.fromHex('#B85855');
    final sortedCategories = snapshot.categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final largestCategory = sortedCategories.isEmpty
        ? null
        : sortedCategories.first;
    String money(double value) => hideAmounts
        ? '•••• TL'
        : NumberFormat.currency(
            locale: 'tr_TR',
            symbol: '₺',
            decimalDigits: 2,
          ).format(value);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 34, 34, 30),
        theme: pw.ThemeData.withFont(base: regular, bold: bold),
        header: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 34,
                    height: 34,
                    decoration: pw.BoxDecoration(
                      color: sage,
                      borderRadius: pw.BorderRadius.circular(10),
                    ),
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Image(maki, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 9),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MakiKoç',
                        style: pw.TextStyle(
                          color: dark,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Kişisel finans ormanı',
                        style: pw.TextStyle(color: green, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Text(
                _dateRange(snapshot),
                style: pw.TextStyle(color: PdfColors.grey700, fontSize: 9),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Verilerin bu cihazda işlendi · Yatırım tavsiyesi değildir.',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 7.5),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
              ),
            ],
          ),
        ),
        build: (context) => [
          pw.Container(
            decoration: pw.BoxDecoration(
              color: green,
              borderRadius: pw.BorderRadius.circular(18),
            ),
            padding: const pw.EdgeInsets.all(22),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${periodLabel(snapshot.period)} finans özeti',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 23,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 7),
                      pw.Text(
                        _summaryMessage(snapshot),
                        style: const pw.TextStyle(
                          color: PdfColor(0.84, 0.92, 0.87),
                          fontSize: 10,
                          lineSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.SizedBox(width: 82, height: 82, child: pw.Image(maki)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _metricCard('Gelir', money(snapshot.totalIncome), sage, dark),
              pw.SizedBox(width: 9),
              _metricCard('Gider', money(snapshot.totalExpense), cream, coral),
              pw.SizedBox(width: 9),
              _metricCard(
                'Net',
                money(snapshot.net),
                snapshot.net >= 0 ? sage : PdfColor.fromHex('#F4DEDA'),
                snapshot.net >= 0 ? green : coral,
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('Harcama dağılımı', green),
          pw.SizedBox(height: 9),
          if (sortedCategories.isEmpty)
            _emptyBlock('Bu dönemde kayıtlı gider bulunmuyor.', cream, dark)
          else
            ...sortedCategories.take(8).map((entry) {
              final ratio = snapshot.totalExpense <= 0
                  ? 0.0
                  : entry.value / snapshot.totalExpense;
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          entry.key,
                          style: pw.TextStyle(
                            color: dark,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),
                        pw.Text(
                          money(entry.value),
                          style: pw.TextStyle(color: dark, fontSize: 9),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints?.maxWidth ?? 480;
                        return pw.Stack(
                          children: [
                            pw.Container(
                              width: width,
                              height: 6,
                              decoration: pw.BoxDecoration(
                                color: sage,
                                borderRadius: pw.BorderRadius.circular(99),
                              ),
                            ),
                            pw.Container(
                              width: width * ratio.clamp(0.0, 1.0),
                              height: 6,
                              decoration: pw.BoxDecoration(
                                color: green,
                                borderRadius: pw.BorderRadius.circular(99),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
          pw.SizedBox(height: 18),
          _sectionTitle('Maki’nin notu', green),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: cream,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: sage),
            ),
            child: pw.Text(
              largestCategory == null
                  ? 'İlk gelir veya gider kaydın bu raporu canlandıracak. Küçük ve düzenli kayıt, kusursuz olmaktan daha değerlidir.'
                  : '${largestCategory.key} bu dönemin en yüksek harcama alanı. Bir sonraki dönemde yalnızca bu alan için gerçekçi, küçük bir sınır belirlemek sürdürülebilir bir başlangıç olabilir.',
              style: pw.TextStyle(color: dark, fontSize: 10, lineSpacing: 3),
            ),
          ),
          if (includeTransactions) ...[
            pw.SizedBox(height: 22),
            _sectionTitle('İşlem dökümü', green),
            pw.SizedBox(height: 8),
            if (snapshot.expenses.isEmpty && snapshot.incomes.isEmpty)
              _emptyBlock('Bu dönemde işlem yok.', cream, dark)
            else
              _transactions(snapshot, money, dark, green, coral),
          ],
        ],
      ),
    );
    return Uint8List.fromList(await document.save());
  }

  static String periodLabel(MakiReportPeriod period) => switch (period) {
    MakiReportPeriod.daily => 'Günlük',
    MakiReportPeriod.weekly => 'Haftalık',
    MakiReportPeriod.monthly => 'Aylık',
  };

  static (DateTime, DateTime) _range(MakiReportPeriod period, DateTime anchor) {
    final day = DateTime(anchor.year, anchor.month, anchor.day);
    return switch (period) {
      MakiReportPeriod.daily => (day, day.add(const Duration(days: 1))),
      MakiReportPeriod.weekly => (
        day.subtract(Duration(days: day.weekday - DateTime.monday)),
        day
            .subtract(Duration(days: day.weekday - DateTime.monday))
            .add(const Duration(days: 7)),
      ),
      MakiReportPeriod.monthly => (
        DateTime(day.year, day.month),
        DateTime(day.year, day.month + 1),
      ),
    };
  }

  static bool _contains(DateTime date, DateTime start, DateTime endExclusive) =>
      !date.isBefore(start) && date.isBefore(endExclusive);

  static String _dateRange(MakiReportSnapshot snapshot) {
    final end = snapshot.endExclusive.subtract(const Duration(days: 1));
    final formatter = DateFormat('dd.MM.yyyy');
    if (snapshot.period == MakiReportPeriod.daily) {
      return formatter.format(snapshot.start);
    }
    return '${formatter.format(snapshot.start)} – ${formatter.format(end)}';
  }

  static String _summaryMessage(MakiReportSnapshot snapshot) {
    final count = snapshot.expenses.length + snapshot.incomes.length;
    if (count == 0) {
      return 'Bu dönem henüz sessiz. İlk kaydın finans ormanında görünür bir iz bırakacak.';
    }
    if (snapshot.net >= 0) {
      return '$count kayıt işlendi. Gelir-gider dengen bu dönemde artıda; sürdürülebilir ritmi koru.';
    }
    return '$count kayıt işlendi. Bu rapor yargılamak için değil, bir sonraki küçük adımı görünür kılmak için burada.';
  }

  static pw.Widget _metricCard(
    String label,
    String value,
    PdfColor background,
    PdfColor foreground,
  ) => pw.Expanded(
    child: pw.Container(
      height: 72,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: background,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(label, style: pw.TextStyle(color: foreground, fontSize: 8)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: foreground,
              fontWeight: pw.FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  static pw.Widget _sectionTitle(String text, PdfColor color) => pw.Text(
    text,
    style: pw.TextStyle(
      color: color,
      fontWeight: pw.FontWeight.bold,
      fontSize: 14,
    ),
  );

  static pw.Widget _emptyBlock(
    String text,
    PdfColor background,
    PdfColor foreground,
  ) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: background,
      borderRadius: pw.BorderRadius.circular(10),
    ),
    child: pw.Text(text, style: pw.TextStyle(color: foreground, fontSize: 9)),
  );

  static pw.Widget _transactions(
    MakiReportSnapshot snapshot,
    String Function(double) money,
    PdfColor dark,
    PdfColor green,
    PdfColor coral,
  ) {
    final rows = <({DateTime date, String title, String type, double amount})>[
      ...snapshot.incomes.map(
        (item) => (
          date: item.date,
          title: item.title,
          type: 'Gelir · ${item.source}',
          amount: item.amount,
        ),
      ),
      ...snapshot.expenses.map(
        (item) => (
          date: item.date,
          title: item.title,
          type: 'Gider · ${item.category}',
          amount: -item.amount,
        ),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));
    return pw.TableHelper.fromTextArray(
      headers: const ['Tarih', 'İşlem', 'Tür', 'Tutar'],
      data: rows
          .map(
            (row) => [
              DateFormat('dd.MM.yyyy').format(row.date),
              row.title,
              row.type,
              money(row.amount.abs()),
            ],
          )
          .toList(growable: false),
      headerDecoration: pw.BoxDecoration(color: green),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
      cellStyle: pw.TextStyle(color: dark, fontSize: 7.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      border: pw.TableBorder(
        horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: .4),
      ),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColor(.97, .97, .95)),
      cellAlignments: const {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }
}
