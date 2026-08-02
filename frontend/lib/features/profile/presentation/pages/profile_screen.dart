import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/features/auth/presentation/utils/avatar_utils.dart';
import 'package:maki_app/l10n/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _displayNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _deleteProfile() async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteDeviceProfileTitle),
        content: Text(l10n.deleteDeviceProfileConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.deleteDeviceProfileButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(DeleteProfileEvent());
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    var avatarPath = pickedFile.path;
    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      avatarPath = 'data:image/png;base64,${base64Encode(bytes)}';
    }
    if (mounted) {
      context.read<AuthBloc>().add(UpdateProfileEvent(avatarUrl: avatarPath));
    }
  }

  Future<void> _showAvatarOptions() async {
    final l10n = AppLocalizations.of(context)!;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.galleryButton),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.cameraButton),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.face_outlined),
              title: Text(l10n.makiMascotOption),
              onTap: () {
                Navigator.pop(sheetContext);
                context.read<AuthBloc>().add(
                  const UpdateProfileEvent(
                    avatarUrl: 'assets/mascot/maki_avatar.webp',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editField({
    required String title,
    required String initialValue,
    required void Function(String) onSave,
    bool allowEmpty = false,
    bool isEmail = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initialValue);
    String? error;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: isEmail
                    ? TextInputType.emailAddress
                    : TextInputType.text,
                decoration: InputDecoration(
                  labelText: title,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (!allowEmpty && value.isEmpty) {
                  setDialogState(() => error = l10n.requiredField);
                  return;
                }
                if (isEmail &&
                    value.isNotEmpty &&
                    !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  setDialogState(() => error = l10n.invalidEmail);
                  return;
                }
                onSave(value);
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _editAge(int? currentAge) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentAge?.toString());
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.ageLabel),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: InputDecoration(
                  labelText: l10n.ageLabel,
                  hintText: l10n.ageHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final age = int.tryParse(controller.text.trim());
                if (age == null || age < 13 || age > 100) {
                  setDialogState(() => error = l10n.invalidAge);
                  return;
                }
                context.read<AuthBloc>().add(UpdateProfileEvent(age: age));
                Navigator.pop(dialogContext);
              },
              child: Text(l10n.saveButton),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void _createProfile() {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _displayNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());
    final email = _emailController.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.requiredField)));
      return;
    }
    if (age == null || age < 13 || age > 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidAge)));
      return;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invalidEmail)));
      return;
    }
    context.read<AuthBloc>().add(
      CreateProfileEvent(displayName: displayName, age: age, email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: MakiAppBarTitle(title: l10n.profileTitle)),
      body: MakiBackground(
        maxContentWidth: 720,
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.user;
            return user == null
                ? _EmptyDeviceProfile(
                    displayNameController: _displayNameController,
                    ageController: _ageController,
                    emailController: _emailController,
                    onCreate: _createProfile,
                  )
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _ProfileHero(
                        displayName: user.displayName,
                        email: user.email,
                        avatarUrl: user.avatarUrl,
                        onAvatarTap: _showAvatarOptions,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.phonelink_lock_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  l10n.deviceProfilePrivacy,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(l10n.displayNameLabel),
                              subtitle: Text(user.displayName),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: () => _editField(
                                title: l10n.editDisplayNameTitle,
                                initialValue: user.displayName,
                                onSave: (value) => context.read<AuthBloc>().add(
                                  UpdateProfileEvent(displayName: value),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.cake_outlined),
                              title: Text(l10n.ageLabel),
                              subtitle: Text(
                                user.age?.toString() ?? l10n.ageMissing,
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: () => _editAge(user.age),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(
                                Icons.alternate_email_outlined,
                              ),
                              title: Text(l10n.optionalEmailLabel),
                              subtitle: Text(
                                user.email.isEmpty
                                    ? l10n.optionalFieldEmpty
                                    : user.email,
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: () => _editField(
                                title: l10n.optionalEmailLabel,
                                initialValue: user.email,
                                allowEmpty: true,
                                isEmail: true,
                                onSave: (value) => context.read<AuthBloc>().add(
                                  UpdateProfileEvent(email: value),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.fingerprint_rounded),
                              title: Text(l10n.deviceProfileIdLabel),
                              subtitle: Text(user.userId),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      OutlinedButton.icon(
                        onPressed: _deleteProfile,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                        icon: const Icon(Icons.person_remove_outlined),
                        label: Text(l10n.deleteDeviceProfileButton),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _EmptyDeviceProfile extends StatelessWidget {
  const _EmptyDeviceProfile({
    required this.displayNameController,
    required this.ageController,
    required this.emailController,
    required this.onCreate,
  });

  final TextEditingController displayNameController;
  final TextEditingController ageController;
  final TextEditingController emailController;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Icon(
          Icons.phonelink_lock_rounded,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.deviceProfileEmptyTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.deviceProfileEmptyBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        TextField(
          controller: displayNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.displayNameLabel,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            labelText: l10n.ageLabel,
            hintText: l10n.ageHint,
            prefixIcon: const Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: l10n.optionalEmailLabel,
            prefixIcon: const Icon(Icons.alternate_email_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.lock_outline_rounded),
          label: Text(l10n.createDeviceProfileButton),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.deviceProfilePrivacy,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.onAvatarTap,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          button: true,
          label: AppLocalizations.of(context)!.changeAvatarLabel,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundImage: AvatarUtils.getAvatarImage(avatarUrl),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    child: const Icon(Icons.camera_alt_outlined, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          displayName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (email.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(email, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
