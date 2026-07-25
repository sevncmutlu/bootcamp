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

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            l10n.deleteAccountTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(l10n.deleteAccountConfirmation),
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
              child: Text(l10n.deleteAccountButton),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await AuthService.instance.deleteAccount();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final oldController = TextEditingController();
    final newController = TextEditingController();
    String? dialogError;
    bool obscureOld = true;
    bool obscureNew = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.changePasswordTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null) ...[
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: oldController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: l10n.currentPasswordLabel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureOld = !obscureOld;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newController,
                    obscureText: obscureNew,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.newPasswordLabel,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: newController.text.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildDialogStrengthIndicator(
                                  newController.text, l10n, theme),
                              const SizedBox(height: 6),
                              _buildDialogRequirementRow(
                                  l10n.reqMinLength,
                                  newController.text.length >= 6,
                                  theme),
                              _buildDialogRequirementRow(
                                  l10n.reqNumber,
                                  RegExp(r'[0-9]').hasMatch(newController.text),
                                  theme),
                              _buildDialogRequirementRow(
                                  l10n.reqUpper,
                                  RegExp(r'[A-Z]').hasMatch(newController.text),
                                  theme),
                              _buildDialogRequirementRow(
                                  l10n.reqSpecial,
                                  RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                                      .hasMatch(newController.text),
                                  theme),
                            ],
                          ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancelButton),
                ),
                TextButton(
                  onPressed: () async {
                    if (oldController.text.isNotEmpty &&
                        newController.text.length >= 6) {
                      final nav = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await AuthService.instance.changePassword(
                          oldPassword: oldController.text,
                          newPassword: newController.text,
                        );
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.changePasswordSuccess)),
                        );
                        nav.pop();
                      } catch (e) {
                        setDialogState(() {
                          dialogError =
                              e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    }
                  },
                  child: Text(l10n.saveButton),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogStrengthIndicator(
      String pass, AppLocalizations l10n, ThemeData theme) {
    if (pass.isEmpty) return const SizedBox.shrink();
    int score = 0;
    if (pass.length >= 6) score++;
    if (RegExp(r'[0-9]').hasMatch(pass)) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(pass)) score++;

    Color color;
    String label;
    double progress;

    if (score <= 1) {
      color = Colors.red;
      label = l10n.passwordWeak;
      progress = 0.33;
    } else if (score <= 3) {
      color = Colors.orange;
      label = l10n.passwordMedium;
      progress = 0.66;
    } else {
      color = Colors.green;
      label = l10n.passwordStrong;
      progress = 1.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${l10n.passwordLabel}: $label',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$score/4',
              style: TextStyle(fontSize: 12, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogRequirementRow(
      String label, bool isMet, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isMet
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
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
    bool isEmail = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    String? dialogError;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dialogError != null) ...[
                    Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
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
                      if (isEmail) {
                        final emailRegex =
                            RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(text)) {
                          setDialogState(() {
                            dialogError = l10n.invalidEmail;
                          });
                          return;
                        }
                      }
                      final nav = Navigator.of(context);
                      try {
                        await onSave(text);
                        if (mounted) setState(() {});
                        nav.pop();
                      } catch (e) {
                        setDialogState(() {
                          dialogError =
                              e.toString().replaceAll('Exception: ', '');
                        });
                      }
                    }
                  },
                  child: Text(l10n.saveButton),
                ),
              ],
            );
          },
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
                          isEmail: true,
                          onSave: (val) => AuthService.instance.updateProfile(
                            email: val,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_outlined),
                      title: Text(l10n.passwordLabel),
                      subtitle: const Text('••••••••'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: _showChangePasswordDialog,
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
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _deleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                ),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(l10n.deleteAccountButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
