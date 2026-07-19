import 'dart:convert';

import 'package:cryptography/cryptography.dart';

final class SignedModelFixture {
  const SignedModelFixture({
    required this.modelBytes,
    required this.manifestBytes,
    required this.publicKey,
  });

  final List<int> modelBytes;
  final List<int> manifestBytes;
  final SimplePublicKey publicKey;
}

Future<SignedModelFixture> signModel({
  required String modelJson,
  required List<String> featureNames,
  String modelVersion = 'test-1',
  String? modelDigest,
  int schemaVersion = 1,
  Map<String, Object>? calibration,
  double decisionThreshold = 0.5,
}) async {
  final algorithm = Ed25519();
  final keyPair = await algorithm.newKeyPairFromSeed(
    List<int>.generate(32, (index) => index + 1),
  );
  final publicKey = await keyPair.extractPublicKey();
  final modelBytes = utf8.encode(modelJson);
  final digest = modelDigest ?? _hex((await Sha256().hash(modelBytes)).bytes);
  final body = <String, Object>{
    'schemaVersion': schemaVersion,
    'modelVersion': modelVersion,
    'featureNames': featureNames,
    'trainedUntil': '2026-06-30T00:00:00.000Z',
    'modelSha256': digest,
    if (schemaVersion == 2) ...{
      'datasetSha256': 'a' * 64,
      'objective': 'binary',
      'calibration':
          calibration ??
          <String, Object>{'method': 'none', 'parameters': <double>[]},
      'decisionThreshold': decisionThreshold,
    },
  };
  final signature = await algorithm.sign(
    utf8.encode(_canonicalJson(body)),
    keyPair: keyPair,
  );
  final manifest = <String, Object>{
    ...body,
    'signature': base64Encode(signature.bytes),
  };
  return SignedModelFixture(
    modelBytes: modelBytes,
    manifestBytes: utf8.encode(jsonEncode(manifest)),
    publicKey: publicKey,
  );
}

String _canonicalJson(Object? value) {
  if (value is Map<String, Object>) {
    final keys = value.keys.toList()..sort();
    final fields = keys.map(
      (key) => '${jsonEncode(key)}:${_canonicalJson(value[key])}',
    );
    return '{${fields.join(',')}}';
  }
  if (value is List<Object>) {
    return '[${value.map(_canonicalJson).join(',')}]';
  }
  return jsonEncode(value);
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
