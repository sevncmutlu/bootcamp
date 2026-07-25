import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/auth_service.dart';
import 'package:maki_app/theme/app_tokens.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.logoutButton,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.logoutConfirmation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
              child: Text(l10n.logoutButton),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await AuthService.instance.logout();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  ImageProvider _getAvatarImage(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const AssetImage('assets/mascot/maki_avatar.webp');
    }
    if (avatarUrl.startsWith('assets/')) {
      return AssetImage(avatarUrl);
    }
    if (kIsWeb || avatarUrl.startsWith('blob:') || avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    }
    final file = File(avatarUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return const AssetImage('assets/mascot/maki_avatar.webp');
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        await AuthService.instance.updateProfile(avatarUrl: pickedFile.path);
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint('Avatar selection error: $e');
    }
  }

  Future<void> _showAvatarOptions() async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(l10n.galleryButton),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(l10n.cameraButton),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.face_outlined),
                title: Text(l10n.makiMascotOption),
                onTap: () async {
                  Navigator.pop(context);
                  await AuthService.instance.updateProfile(
                    avatarUrl: 'assets/mascot/maki_avatar.webp',
                  );
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required Future<void> Function(String) onSave,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final nav = Navigator.of(context);
                  await onSave(text);
                  if (mounted) setState(() {});
                  nav.pop();
                }
              },
              child: Text(l10n.saveButton),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final user = AuthService.instance.currentUser;
    final avatarImage = _getAvatarImage(user?.avatarUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.3),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.4),
                          width: 3,
                        ),
                        image: DecorationImage(
                          image: avatarImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showAvatarOptions,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Text(
                user?.displayName ?? l10n.guestUser,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user?.email ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Card(
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.card,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(l10n.displayNameLabel),
                      subtitle: Text(user?.displayName ?? '-'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editField(
                          title: l10n.editDisplayNameTitle,
                          initialValue: user?.displayName ?? '',
                          onSave: (val) => AuthService.instance.updateProfile(
                            displayName: val,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(l10n.emailLabel),
                      subtitle: Text(user?.email ?? '-'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editField(
                          title: l10n.editEmailTitle,
                          initialValue: user?.email ?? '',
                          onSave: (val) => AuthService.instance.updateProfile(
                            email: val,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(l10n.userIdLabel),
                      subtitle: Text(user?.userId ?? '-'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.logoutButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
