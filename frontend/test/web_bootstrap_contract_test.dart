import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'web opening screen is removed after Flutter paints its first frame',
    () {
      final html = File('web/index.html').readAsStringSync();

      expect(html, contains("addEventListener('flutter-first-frame'"));
      expect(html, contains("document.querySelector('.maki-boot')"));
      expect(html, contains('bootScreen.remove()'));
    },
  );
}
