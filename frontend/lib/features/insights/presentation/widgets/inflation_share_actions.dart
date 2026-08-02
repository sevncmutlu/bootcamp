part of '../pages/inflation_screen.dart';

extension _InflationMakiShareCardActions on _InflationMakiShareCardState {
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

  String _money(BuildContext context, double value) =>
      formatTL(value, decimals: 0, context: context);

  Future<Uint8List> _capturePng() async {
    await WidgetsBinding.instance.endOfFrame;
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('Finance summary card is not ready to export.');
    }
    final pixelRatio = (1600 / boundary.size.width).clamp(1.5, 3.0).toDouble();
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Finance summary card could not be rendered.');
    }
    return byteData.buffer.asUint8List();
  }

  String _comparisonText(BuildContext context) {
    final isTurkish = Localizations.localeOf(context).languageCode == 'tr';
    if (widget.personalSpendingChange == null) {
      final progress = isTurkish
          ? 'Güncel dönemde ${widget.currentTransactionCount}, önceki dönemde ${widget.previousTransactionCount} tüketim giderin var; karşılaştırma için iki dönemde de en az 3 kayıt gerekiyor.'
          : 'You have ${widget.currentTransactionCount} current and ${widget.previousTransactionCount} previous consumption records; each period needs at least 3.';
      if (widget.officialInflation == null) return progress;
      return isTurkish
          ? 'TÜİK aylık oranı ${_percent(context, widget.officialInflation!)}. $progress'
          : 'Monthly TÜİK inflation is ${_percent(context, widget.officialInflation!)}. $progress';
    }
    if (widget.officialInflation == null) {
      return isTurkish
          ? 'Harcama değişimin ${_percent(context, widget.personalSpendingChange!)}. TÜİK karşılaştırması şu anda çevrimdışı.'
          : 'Your spending change is ${_percent(context, widget.personalSpendingChange!)}. TÜİK comparison is currently offline.';
    }
    final direction =
        widget.personalSpendingChange! <= widget.officialInflation!
        ? (isTurkish ? 'altında' : 'below')
        : (isTurkish ? 'üzerinde' : 'above');
    return isTurkish
        ? 'Harcama değişimin TÜİK aylık oranının ${_percent(context, _difference!)} puan $direction.'
        : 'Your spending change is ${_percent(context, _difference!)} points $direction monthly TÜİK inflation.';
  }
}
