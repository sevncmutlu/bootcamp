import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';

enum MascotPose { wave, happy, thinking, celebrate, sleeping, neutral }

class Mascot extends StatelessWidget {
  const Mascot({
    super.key,
    this.pose = MascotPose.neutral,
    this.size = 96,
    this.withBadge = true,
  }) : _isAvatar = false;

  const Mascot.avatar({super.key, this.pose = MascotPose.happy, this.size = 32})
    : withBadge = true,
      _isAvatar = true;

  final MascotPose pose;
  final double size;

  final bool withBadge;

  final bool _isAvatar;

  static const Map<MascotPose, String> _poseAsset = {
    MascotPose.wave: 'assets/mascot/maki_wave.webp',
    MascotPose.thinking: 'assets/mascot/maki_thinking.webp',
    MascotPose.celebrate: 'assets/mascot/maki_celebrate.webp',
    MascotPose.happy: 'assets/mascot/maki_happy.webp',
    MascotPose.neutral: 'assets/mascot/maki_neutral.webp',
    MascotPose.sleeping: 'assets/mascot/maki_sleeping.webp',
  };

  static const String _avatarAsset = 'assets/mascot/maki_avatar.webp';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final assetPath = _isAvatar
        ? _avatarAsset
        : (_poseAsset[pose] ?? _avatarAsset);
    final artSize = size * (withBadge ? 0.82 : 1);

    final art = Image.asset(
      assetPath,
      width: artSize,
      height: artSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stack) => CustomPaint(
        size: Size.square(artSize),
        painter: _MascotFace(pose: pose),
      ),
    );

    if (!withBadge) {
      return SizedBox.square(
        dimension: size,
        child: Center(child: art),
      );
    }

    return SizedBox.square(
      dimension: size,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ForestColors.sage.withValues(alpha: 0.45),
              scheme.primary.withValues(alpha: 0.18),
            ],
          ),
          border: Border.all(
            color: scheme.primary.withValues(alpha: 0.25),
            width: size * 0.02,
          ),
        ),
        child: ClipOval(child: art),
      ),
    );
  }
}

class _MascotFace extends CustomPainter {
  _MascotFace({required this.pose});

  final MascotPose pose;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final bodyColor = const Color(0xFFC9873F); // Sıcak maskot kahvesi.
    final bellyColor = const Color(0xFFF2E4CE);
    final earColor = const Color(0xFFB9762F);

    final body = Paint()..color = bodyColor;
    final belly = Paint()..color = bellyColor;
    final ear = Paint()..color = earColor;

    canvas.drawCircle(Offset(w * 0.28, h * 0.24), w * 0.12, ear);
    canvas.drawCircle(Offset(w * 0.72, h * 0.24), w * 0.12, ear);

    final headRect = Rect.fromCenter(
      center: Offset(cx, h * 0.55),
      width: w * 0.82,
      height: h * 0.72,
    );
    canvas.drawOval(headRect, body);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.66),
        width: w * 0.5,
        height: h * 0.42,
      ),
      belly,
    );

    canvas.drawCircle(Offset(cx, h * 0.24), w * 0.09, body);

    final eyePaint = Paint()..color = const Color(0xFF2B2320);
    final eyeY = h * 0.5;
    if (pose == MascotPose.sleeping) {
      final lid = Paint()
        ..color = const Color(0xFF2B2320)
        ..strokeWidth = w * 0.03
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx - w * 0.18, eyeY), radius: w * 0.07),
        0.2,
        2.7,
        false,
        lid,
      );
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx + w * 0.18, eyeY), radius: w * 0.07),
        0.2,
        2.7,
        false,
        lid,
      );
    } else {
      canvas.drawCircle(Offset(cx - w * 0.18, eyeY), w * 0.055, eyePaint);
      canvas.drawCircle(Offset(cx + w * 0.18, eyeY), w * 0.055, eyePaint);
      final glint = Paint()..color = Colors.white.withValues(alpha: 0.9);
      canvas.drawCircle(
        Offset(cx - w * 0.16, eyeY - h * 0.015),
        w * 0.018,
        glint,
      );
      canvas.drawCircle(
        Offset(cx + w * 0.20, eyeY - h * 0.015),
        w * 0.018,
        glint,
      );
    }

    if (pose == MascotPose.happy || pose == MascotPose.celebrate) {
      final cheek = Paint()
        ..color = const Color(0xFFE8896B).withValues(alpha: 0.5);
      canvas.drawCircle(Offset(cx - w * 0.30, h * 0.60), w * 0.06, cheek);
      canvas.drawCircle(Offset(cx + w * 0.30, h * 0.60), w * 0.06, cheek);
    }

    final nose = Paint()..color = const Color(0xFF7A4A3A);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.62),
        width: w * 0.09,
        height: w * 0.07,
      ),
      nose,
    );

    final mouth = Paint()
      ..color = const Color(0xFF7A4A3A)
      ..strokeWidth = w * 0.022
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final my = h * 0.70;
    if (pose == MascotPose.celebrate) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, my - h * 0.02), radius: w * 0.10),
        0.25,
        2.64,
        false,
        mouth,
      );
    } else {
      final path = Path()
        ..moveTo(cx - w * 0.06, my)
        ..quadraticBezierTo(cx, my + h * 0.03, cx + w * 0.06, my);
      canvas.drawPath(path, mouth);
    }
  }

  @override
  bool shouldRepaint(covariant _MascotFace old) => old.pose != pose;
}
