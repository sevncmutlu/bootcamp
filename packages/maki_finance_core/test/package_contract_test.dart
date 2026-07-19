import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('paket Flutter bağımlılığı taşımaz', () {
    final yaml = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    final dependencies = yaml['dependencies'] as YamlMap;
    final environment = yaml['environment'] as YamlMap;

    expect(dependencies.containsKey('flutter'), isFalse);
    expect(environment['sdk'], '^3.9.2');
  });
}
