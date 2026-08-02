import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maki_app/core/config/app_environment.dart';
import 'package:maki_app/core/config/capability_registry.dart';
import 'package:maki_app/core/di/injection_container.dart' as di;
import 'package:maki_app/core/theme/app_tokens.dart';
import 'package:maki_app/core/widgets/maki_app_bar_title.dart';
import 'package:maki_app/core/widgets/maki_background.dart';
import 'package:maki_app/features/session/domain/maki_session.dart';
import 'package:maki_app/features/session/presentation/cubit/session_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectionPrivacyScreen extends StatelessWidget {
  const ConnectionPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final environment = di.sl<AppEnvironment>();
    final capabilities = di.sl<CapabilityRegistry>();
    return Scaffold(
      appBar: AppBar(
        title: const MakiAppBarTitle(title: 'Bağlantı ve gizlilik'),
      ),
      body: MakiBackground(
        maxContentWidth: 920,
        child: BlocBuilder<SessionCubit, MakiSession>(
          builder: (context, session) => ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              _TrustCircle(session: session),
              const SizedBox(height: AppSpacing.xl),
              _SessionPanel(session: session, configured: environment.hasOidc),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Nerede ne çalışır?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'MakiDisplay',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _CapabilityGrid(session: session, capabilities: capabilities),
              const SizedBox(height: AppSpacing.xl),
              _PrivacyPanel(environment: environment),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustCircle extends StatelessWidget {
  const _TrustCircle({required this.session});

  final MakiSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = session.isAuthenticated;
    return Semantics(
      label: connected
          ? 'Bu cihaz Maki hizmetlerine güvenli biçimde bağlı.'
          : 'Finans kayıtları yalnız bu cihazda.',
      child: Center(
        child: SizedBox.square(
          dimension: 260,
          child: CustomPaint(
            painter: _TrustRingPainter(
              color: theme.colorScheme.primary,
              connected: connected,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    connected
                        ? Icons.lock_rounded
                        : Icons.phone_android_rounded,
                    color: theme.colorScheme.primary,
                    size: 34,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    connected ? 'Güvenli bağ kuruldu' : 'Önce cihazın',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'MakiDisplay',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    connected
                        ? 'Yerel finans alanın korunur; yalnız istediğin çevrim içi özellik bağlanır.'
                        : 'Gelir, gider ve planların hesap açmadan bu cihazda çalışır.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  const _TrustRingPainter({required this.color, required this.connected});

  final Color color;
  final bool connected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    for (var index = 0; index < 5; index++) {
      final radius = 92.0 + index * 10;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = index == 0 ? 2.2 : 1
        ..color = color.withValues(
          alpha: connected ? 0.34 - index * 0.04 : 0.18,
        );
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        -1.7 + index * 0.08,
        5.4 - index * 0.11,
        false,
        paint,
      );
    }
    if (connected) {
      canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.22),
        6,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_TrustRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.connected != connected;
}

class _SessionPanel extends StatelessWidget {
  const _SessionPanel({required this.session, required this.configured});

  final MakiSession session;
  final bool configured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connected = session.isAuthenticated;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: AppRadius.card,
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.lg,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 480,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connected
                      ? (session.displayName ?? 'Maki hesabın bağlı')
                      : 'Hesap bağlantısı isteğe bağlı',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  session.message ?? 'Yerel kullanım hazır.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (connected && session.email != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    session.email!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (configured && !session.isDevelopmentSession)
            connected
                ? OutlinedButton.icon(
                    onPressed: session.isBusy
                        ? null
                        : () => context.read<SessionCubit>().disconnect(),
                    icon: const Icon(Icons.link_off_rounded),
                    label: const Text('Bağlantıyı kes'),
                  )
                : FilledButton.icon(
                    onPressed: session.isBusy
                        ? null
                        : () => context.read<SessionCubit>().connect(),
                    icon: session.isBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.lock_open_rounded),
                    label: Text(
                      session.isBusy ? 'Bağlanıyor…' : 'Hesabımı bağla',
                    ),
                  ),
        ],
      ),
    );
  }
}

class _CapabilityGrid extends StatelessWidget {
  const _CapabilityGrid({required this.session, required this.capabilities});

  final MakiSession session;
  final CapabilityRegistry capabilities;

  @override
  Widget build(BuildContext context) {
    final online = capabilities.onlineFeaturesAvailable(
      hasSession: session.isAuthenticated,
    );
    final items = [
      const (
        Icons.account_balance_wallet_outlined,
        'Gelir, gider ve plan',
        'Her zaman · bu cihazda',
      ),
      (
        Icons.document_scanner_outlined,
        'Fiş tarama',
        online ? 'Bağlantı hazır' : 'Hesap bağlayınca',
      ),
      (
        Icons.auto_awesome_outlined,
        'Maki Koç',
        online ? 'Kaynaklı öneriler hazır' : 'Hesap bağlayınca',
      ),
      (
        Icons.workspace_premium_outlined,
        'Pro abonelik',
        capabilities.nativeStoreSupported
            ? 'Mobil mağazada'
            : 'Mobil uygulamadan alınır',
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final width =
            (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;
        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: _CapabilityTile(
                  icon: item.$1,
                  title: item.$2,
                  detail: item.$3,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CapabilityTile extends StatelessWidget {
  const _CapabilityTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.md)),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel({required this.environment});

  final AppEnvironment environment;

  Future<void> _open(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sınırlar net',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Maki parolanı saklamaz. Finans kayıtların yerelde kalır; çevrim içi özellikler yalnız güvenli erişim belirteciyle çalışır.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (environment.privacyUri case final uri?)
                TextButton.icon(
                  onPressed: () => _open(context, uri),
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Gizlilik'),
                ),
              if (environment.termsUri case final uri?)
                TextButton.icon(
                  onPressed: () => _open(context, uri),
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Kullanım koşulları'),
                ),
              if (!environment.hasLegalLinks)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    'Yasal bağlantılar yayın yapılandırmasında eklenecek.',
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
