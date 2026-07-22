import 'package:flutter/material.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/mara_theme.dart';
import 'compact_hero_slide.dart';

/// Slide de Medic Plus — naranja Farma Express.
class MedicPlusHeroSlide extends StatelessWidget {
  const MedicPlusHeroSlide({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CompactHeroSlide(
      onTap: onTap,
      badge: BrandConfig.medicPlusName.toUpperCase(),
      title: 'Medic Plus: consulta desde Farma Express',
      subtitle: BrandConfig.medicPlusSubtitle,
      colors: const [
        MaraColors.green,
        MaraColors.greenDark,
        Color(0xFFCC4A00),
      ],
      emoji: '👨‍⚕️',
      ctaLabel: 'Consultar ahora',
      ctaLeadingIcon: Icons.video_camera_front_outlined,
    );
  }
}
