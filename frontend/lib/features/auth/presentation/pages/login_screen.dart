import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/features/auth/presentation/pages/register_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/password_strength_indicator.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginEvent(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  Future<void> _showForgotPasswordDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final emailController = TextEditingController(text: _emailController.text);
    final newPasswordController = TextEditingController();
    bool obscureNew = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                l10n.resetPasswordTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordController,
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
                    child: newPasswordController.text.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PasswordStrengthIndicator(
                                password: newPasswordController.text,
                              ),
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
                    final email = emailController.text.trim();
                    final newPass = newPasswordController.text;
                    if (email.isNotEmpty && newPass.length >= 6) {
                        context.read<AuthBloc>().add(
                              ResetPasswordEvent(
                                email: email,
                                newPassword: newPass,
                              ),
                            );
                        Navigator.pop(context);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.loginButton),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const Center(
                  child: Mascot(pose: MascotPose.happy, size: 100),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                TextFormField(
                  key: const Key('login_email_field'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.emailLabel;
                    }
                    final emailRegex =
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(val.trim())) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
                  key: const Key('login_password_field'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: l10n.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return l10n.passwordLabel;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      l10n.forgotPassword,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                BlocConsumer<AuthBloc, AuthState>(
                  listener: (context, state) {
                    if (state.status == AuthStatus.authenticated) {
                      Navigator.of(context).pop(true);
                    } else if (state.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error!),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state.isSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.changePasswordSuccess),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isLoading ? null : _submitLogin,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.loginButton),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.dontHaveAccount),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(l10n.continueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
