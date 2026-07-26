import 'package:flutter/material.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/features/auth/presentation/pages/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:maki_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/mascot.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  bool get _hasMinLength => _passwordController.text.length >= 6;
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(_passwordController.text);
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_passwordController.text);
  bool get _hasSpecial =>
      RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text);

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasNumber) score++;
    if (_hasUpper) score++;
    if (_hasSpecial) score++;
    return score;
  }

  Widget _buildStrengthIndicator(AppLocalizations l10n, ThemeData theme) {
    final pass = _passwordController.text;
    if (pass.isEmpty) return const SizedBox.shrink();

    final score = _strengthScore;
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
        const SizedBox(height: AppSpacing.xs),
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

  Widget _buildRequirementRow(String label, bool isMet, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
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

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          RegisterEvent(
            displayName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.registerButton),
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
                  child: Mascot(pose: MascotPose.celebrate, size: 100),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.registerTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.registerSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.displayNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.displayNameLabel;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                TextFormField(
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
                    if (val == null || val.length < 6) {
                      return l10n.passwordLabel;
                    }
                    return null;
                  },
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _passwordController.text.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppSpacing.xs),
                            _buildStrengthIndicator(l10n, theme),
                            const SizedBox(height: AppSpacing.sm),
                            _buildRequirementRow(
                                l10n.reqMinLength, _hasMinLength, theme),
                            _buildRequirementRow(
                                l10n.reqNumber, _hasNumber, theme),
                            _buildRequirementRow(
                                l10n.reqUpper, _hasUpper, theme),
                            _buildRequirementRow(
                                l10n.reqSpecial, _hasSpecial, theme),
                          ],
                        ),
                ),
                const SizedBox(height: AppSpacing.xl),

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
                    }
                  },
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isLoading ? null : _submitRegister,
                      child: state.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.registerButton),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  child: Text(l10n.alreadyHaveAccount),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
