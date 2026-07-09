import 'package:flutter/material.dart';

import 'compact_hero_slide.dart';

/// Slide hero de Dog Plus — primer slide del carrusel.
class DogPlusHeroSlide extends StatelessWidget {
  const DogPlusHeroSlide({super.key});

  @override
  Widget build(BuildContext context) {
    return const CompactHeroSlide(
      badge: 'DOG PLUS EXPRESS',
      title: '¿Antojo de un Dog Plus?',
      subtitle: 'Delivery rápido · Descuento en la app',
      colors: [Color(0xFFFF9800), Color(0xFFE65100), Color(0xFFBF360C)],
      emoji: '🌭',
      ctaLabel: 'Hacer pedido',
    );
  }
}
