import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'model_manifest.dart';

/// Model bütünlüğü veya imzası doğrulanamadı.
final class ModelVerificationException implements Exception {
  const ModelVerificationException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Model manifestinin imzasını ve dosya özetini doğrular.
final class ModelVerifier {
  ModelVerifier({
    required this.publicKey,
    Ed25519? signatureAlgorithm,
    Sha256? digestAlgorithm,
  }) : _signatureAlgorithm = signatureAlgorithm ?? Ed25519(),
       _digestAlgorithm = digestAlgorithm ?? Sha256();

  static const _maximumModelBytes = 16 * 1024 * 1024;
  static const _maximumManifestBytes = 64 * 1024;

  final SimplePublicKey publicKey;
  final Ed25519 _signatureAlgorithm;
  final Sha256 _digestAlgorithm;

  Future<ModelManifest> verify({
    required List<int> modelBytes,
    required List<int> manifestBytes,
  }) async {
    if (modelBytes.isEmpty || modelBytes.length > _maximumModelBytes) {
      throw const ModelVerificationException(
        code: 'MODEL_SIZE_INVALID',
        message: 'Model dosyası boş veya boyut sınırını aşıyor.',
      );
    }
    if (manifestBytes.isEmpty || manifestBytes.length > _maximumManifestBytes) {
      throw const ModelVerificationException(
        code: 'MANIFEST_SIZE_INVALID',
        message: 'Model manifesti boş veya boyut sınırını aşıyor.',
      );
    }

    final ModelManifest manifest;
    try {
      manifest = ModelManifest.parse(manifestBytes);
    } on ModelManifestException catch (error) {
      throw ModelVerificationException(
        code: 'MANIFEST_INVALID',
        message: error.message,
      );
    }

    final List<int> signatureBytes;
    try {
      signatureBytes = base64Decode(manifest.signature);
    } on FormatException {
      throw const ModelVerificationException(
        code: 'SIGNATURE_INVALID',
        message: 'Model imzası Base64 biçiminde değil.',
      );
    }
    if (signatureBytes.length != 64) {
      throw const ModelVerificationException(
        code: 'SIGNATURE_INVALID',
        message: 'Model imzası 64 bayt olmalıdır.',
      );
    }

    final verified = await _signatureAlgorithm.verify(
      manifest.canonicalBodyBytes(),
      signature: Signature(signatureBytes, publicKey: publicKey),
    );
    if (!verified) {
      throw const ModelVerificationException(
        code: 'SIGNATURE_MISMATCH',
        message: 'Model manifesti imzası doğrulanamadı.',
      );
    }

    final digest = await _digestAlgorithm.hash(modelBytes);
    if (_hex(digest.bytes) != manifest.modelSha256) {
      throw const ModelVerificationException(
        code: 'MODEL_DIGEST_MISMATCH',
        message: 'Model dosyası özeti manifestle uyuşmuyor.',
      );
    }
    return manifest;
  }
}

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
