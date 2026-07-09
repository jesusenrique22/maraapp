import 'package:flutter/material.dart';

import '../../core/theme/mara_theme.dart';

class MaraLogo extends StatelessWidget {
  const MaraLogo({
    super.key,
    this.height = 72,
    this.showTagline = false,
    this.dark = false,
  });

  final double height;
  final bool showTagline;

  /// Wordmark claro sobre fondos oscuros (sidebar admin, login).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return _MaraWordmarkDark(height: height, showTagline: showTagline);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/maraplus_logo.png',
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _MaraWordmarkDark(height: height),
        ),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Tu farmacia de confianza',
            style: TextStyle(
              color: MaraColors.textSecondary,
              fontSize: height * 0.17,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// Logo vectorial de marca — sin fondo JPEG, legible en sidebar oscuro.
class _MaraWordmarkDark extends StatelessWidget {
  const _MaraWordmarkDark({
    required this.height,
    this.showTagline = false,
  });

  final double height;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final titleSize = height * 0.52;
    final subSize = height * 0.2;
    final plusSize = height * 0.42;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'MARA',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: MaraColors.green,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'PLUS',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(width: height * 0.08),
            _MaraPlusSymbol(size: plusSize),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: height * 0.02, top: height * 0.04),
          child: Text(
            'FARMACIA',
            style: TextStyle(
              fontSize: subSize,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: height * 0.06,
              height: 1,
            ),
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: height * 0.12),
          Text(
            'Tu farmacia de confianza',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: height * 0.17,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class _MaraPlusSymbol extends StatelessWidget {
  const _MaraPlusSymbol({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final barW = size * 0.28;
    final barH = size;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: barW,
            height: barH,
            decoration: BoxDecoration(
              color: MaraColors.green,
              borderRadius: BorderRadius.circular(barW),
            ),
          ),
          Container(
            width: barH,
            height: barW,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white,
                ],
              ),
              borderRadius: BorderRadius.circular(barW),
            ),
          ),
        ],
      ),
    );
  }
}
