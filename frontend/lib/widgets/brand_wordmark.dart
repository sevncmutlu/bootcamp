import 'package:flutter/material.dart';
import 'package:maki_app/theme/app_tokens.dart';

class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 28,
    this.showTagline = true,
    this.alignment = CrossAxisAlignment.center,
  });

  final double fontSize;

  final bool showTagline;

  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final makiColor = isDark
        ? ForestColors.emeraldLight
        : ForestColors.emeraldDark;
    final kocColor = isDark ? ForestColors.moss : ForestColors.emerald;

    final rowMainAxis = alignment == CrossAxisAlignment.center
        ? MainAxisAlignment.center
        : MainAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: rowMainAxis,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.eco, size: fontSize * 0.9, color: kocColor),
            SizedBox(width: fontSize * 0.22),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Maki',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: makiColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                  TextSpan(
                    text: 'Koç',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: kocColor,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          SizedBox(height: fontSize * 0.12),
          Text(
            'Kişisel Finans Koçun',
            style: TextStyle(
              fontSize: fontSize * 0.42,
              fontWeight: FontWeight.w500,
              color: ForestColors.neutral,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}
