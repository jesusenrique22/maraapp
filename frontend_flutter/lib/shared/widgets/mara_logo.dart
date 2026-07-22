import 'package:flutter/material.dart';

import '../../core/config/brand_config.dart';
import '../../core/theme/mara_theme.dart';

/// Wordmark Farma Express — solo tipografía, sin card ni pastilla.
class MaraLogo extends StatelessWidget {
  const MaraLogo({
    super.key,
    this.height = 72,
    this.showTagline = false,
    this.dark = false,
  });

  final double height;
  final bool showTagline;

  /// Sobre fondos oscuros: texto blanco.
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final titleSize = (height * 0.52).clamp(16.0, 44.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FARMA EXPRESS',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: dark ? Colors.white : MaraColors.green,
            height: 1,
            letterSpacing: -0.8,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: height * 0.14),
          Text(
            BrandConfig.tagline,
            style: TextStyle(
              color: dark
                  ? Colors.white.withValues(alpha: 0.7)
                  : MaraColors.textSecondary,
              fontSize: (height * 0.16).clamp(11.0, 14.0),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.15,
            ),
          ),
        ],
      ],
    );
  }
}
