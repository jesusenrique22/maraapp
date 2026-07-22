import 'package:flutter/material.dart';

import 'compact_hero_slide.dart';

/// Publicidad Cashea — card amarilla (marca) + CTA Farma Express.
class CasheaHeroSlide extends StatelessWidget {
  const CasheaHeroSlide({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CompactHeroSlide(
      onTap: onTap,
      badge: 'CASHEA',
      title: 'Paga con Cashea en Farma Express',
      subtitle: 'Llévalo hoy · Inicial + cuotas sin interés',
      colors: const [
        Color(0xFFFAFF00),
        Color(0xFFF5FF66),
        Color(0xFFE8F000),
      ],
      ctaLabel: 'Ver cómo funciona',
      ctaLeadingIcon: Icons.payments_outlined,
    );
  }
}
