import 'package:flutter/material.dart';

import '../../../../core/config/brand_config.dart';
import 'compact_hero_slide.dart';
import 'mara_puntos_sheet.dart';

/// Banner de fidelización Club FarmaExpress (violeta, no naranja).
class MaraPuntosHeroSlide extends StatelessWidget {
  const MaraPuntosHeroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactHeroSlide(
      onTap: () => MaraPuntosSheet.show(context),
      badge: BrandConfig.loyaltyName.toUpperCase(),
      title: BrandConfig.loyaltyTitle,
      subtitle: BrandConfig.loyaltySubtitle,
      colors: const [
        Color(0xFF7C3AED),
        Color(0xFF6D28D9),
        Color(0xFF4C1D95),
      ],
      emoji: '⭐',
      ctaLabel: 'Ver programa',
      ctaLeadingIcon: Icons.stars_rounded,
    );
  }
}
