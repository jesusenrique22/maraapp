import 'package:flutter/material.dart';

import 'compact_hero_slide.dart';

/// Slide de Medic Plus — mismo formato que el resto del carrusel.
class MedicPlusHeroSlide extends StatelessWidget {
  const MedicPlusHeroSlide({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CompactHeroSlide(
      onTap: onTap,
      badge: 'NUEVO SERVICIO',
      title: 'Medic Plus: Consultas Online',
      subtitle: 'Videollamada con especialistas y receta digital',
      colors: const [
        Color(0xFF1976D2),
        Color(0xFF0D47A1),
        Color(0xFF0D3468),
      ],
      emoji: '👨‍⚕️',
      ctaLabel: 'Consultar ahora',
      ctaLeadingIcon: Icons.video_camera_front_outlined,
    );
  }
}
