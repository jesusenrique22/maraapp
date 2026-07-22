import 'package:flutter/material.dart';

/// Acentos Cashea suaves (sin negro+amarillo agresivo).
class CasheaColors {
  static const yellow = Color(0xFFFFF59D);
  static const yellowSoft = Color(0xFFFFFDE7);
  static const ink = Color(0xFF1A1A1A);
}

/// Wordmark limpio: ícono C amarillo claro + “cashea” en texto oscuro.
class CasheaWordmark extends StatelessWidget {
  const CasheaWordmark({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    final icon = height * 0.92;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: icon,
          height: icon,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEB3B),
            borderRadius: BorderRadius.circular(icon * 0.22),
          ),
          child: Text(
            'c',
            style: TextStyle(
              color: CasheaColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: icon * 0.55,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: height * 0.22),
        Text(
          'cashea',
          style: TextStyle(
            color: CasheaColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: height * 0.52,
            letterSpacing: -0.4,
            height: 1,
          ),
        ),
      ],
    );
  }
}

/// Alias usado en checkout / carrito.
class CasheaBadge extends StatelessWidget {
  const CasheaBadge({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) => CasheaWordmark(height: height);
}

/// Logo asset (si hace falta); preferir [CasheaWordmark] en UI.
class CasheaLogo extends StatelessWidget {
  const CasheaLogo({super.key, this.height = 28});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/cashea_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => CasheaWordmark(height: height),
    );
  }
}
