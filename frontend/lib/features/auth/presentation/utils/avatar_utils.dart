import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AvatarUtils {
  static ImageProvider getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/mascot/maki_avatar.webp');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }
    if (avatarUrl.startsWith('http://') ||
        avatarUrl.startsWith('https://') ||
        avatarUrl.startsWith('blob:') ||
        avatarUrl.startsWith('data:')) {
      return NetworkImage(avatarUrl);
    }
    if (!kIsWeb) {
      try {
        final file = File(avatarUrl);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
    }
    return const AssetImage('assets/mascot/maki_avatar.webp');
  }
}
