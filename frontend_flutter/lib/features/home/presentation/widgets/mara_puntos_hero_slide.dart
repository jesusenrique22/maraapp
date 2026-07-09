import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import 'compact_hero_slide.dart';
import 'mara_puntos_sheet.dart';

/// Banner de fidelización MaraPuntos — programa de puntos (próximamente).
class MaraPuntosHeroSlide extends StatelessWidget {
  const MaraPuntosHeroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactHeroSlide(
      onTap: () => MaraPuntosSheet.show(context),
      badge: 'CLUB MARAPLUS',
      title: '¡Haz tu primera compra y suma puntos!',
      subtitle: 'Acumula MaraPuntos para canjearlos por descuentos',
      colors: const [
        MaraColors.violet,
        Color(0xFF6D28D9),
        Color(0xFFDB2777),
      ],
      emoji: '⭐',
      ctaLabel: 'Ver programa',
      ctaLeadingIcon: Icons.stars_rounded,
    );
  }
}
