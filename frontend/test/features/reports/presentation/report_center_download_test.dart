import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maki_app/features/reports/presentation/pages/report_center_screen.dart';
import 'package:public_file_saver/public_file_saver.dart';

void main() {
  test('Android raporunu sistemin farklı kaydet ekranına gönderir', () async {
    final saver = _RecordingFileSaver();
    final bytes = Uint8List.fromList(<int>[37, 80, 68, 70]);

    final result = await saveMakiReportPdf(
      bytes: bytes,
      fileName: 'maki-haftalik.pdf',
      saver: saver,
      useSaveDialog: true,
    );

    expect(saver.dialogCalls, 1);
    expect(saver.directCalls, 0);
    expect(saver.lastFileName, 'maki-haftalik.pdf');
    expect(saver.lastMimeType, 'application/pdf');
    expect(saver.lastBytes, bytes);
    expect(result?.uri, 'content://maki/maki-haftalik.pdf');
  });

  test('web raporunu tarayıcının doğrudan indirme akışına gönderir', () async {
    final saver = _RecordingFileSaver();

    await saveMakiReportPdf(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
      fileName: 'maki-gunluk.pdf',
      saver: saver,
      useSaveDialog: false,
    );

    expect(saver.dialogCalls, 0);
    expect(saver.directCalls, 1);
    expect(saver.lastSubDir, 'Maki');
  });

  test('kullanıcı sistem ekranını kapatırsa iptal sonucu korunur', () async {
    final saver = _RecordingFileSaver(returnNull: true);

    final result = await saveMakiReportPdf(
      bytes: Uint8List.fromList(<int>[37, 80, 68, 70]),
      fileName: 'maki-aylik.pdf',
      saver: saver,
      useSaveDialog: true,
    );

    expect(result, isNull);
  });
}

class _RecordingFileSaver extends PublicFileSaver {
  _RecordingFileSaver({this.returnNull = false});

  final bool returnNull;
  int directCalls = 0;
  int dialogCalls = 0;
  Uint8List? lastBytes;
  String? lastFileName;
  String? lastMimeType;
  String? lastSubDir;

  @override
  Future<PublicSavedFile?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
    String? subDir,
  }) async {
    directCalls += 1;
    lastBytes = bytes;
    lastFileName = fileName;
    lastMimeType = mimeType;
    lastSubDir = subDir;
    if (returnNull) return null;
    return PublicSavedFile(fileName: fileName, path: 'Downloads/$fileName');
  }

  @override
  Future<PublicSavedFile?> saveBytesWithDialog({
    required Uint8List bytes,
    required String fileName,
    String mimeType = 'application/octet-stream',
    List<String>? fileSuffixChoices,
  }) async {
    dialogCalls += 1;
    lastBytes = bytes;
    lastFileName = fileName;
    lastMimeType = mimeType;
    if (returnNull) return null;
    return PublicSavedFile(fileName: fileName, uri: 'content://maki/$fileName');
  }
}
