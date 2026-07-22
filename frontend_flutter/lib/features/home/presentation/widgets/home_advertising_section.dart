import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'banner_carousel.dart';
import 'cashea_hero_slide.dart';
import 'mara_puntos_hero_slide.dart';
import 'medic_plus_hero_slide.dart';

/// Carrusel Farma Express: Cashea + Club + Salud360 + banners del catálogo.
class HomeAdvertisingSection extends StatelessWidget {
  const HomeAdvertisingSection({
    super.key,
    required this.heroBanners,
    this.stripBanners = const [],
    required this.onMedicPlusTap,
    this.bannersLoading = false,
  });

  final List<PromoBanner> heroBanners;
  final List<PromoBanner> stripBanners;
  final VoidCallback onMedicPlusTap;
  final bool bannersLoading;

  @override
  Widget build(BuildContext context) {
    final leadingSlides = <Widget>[
      const CasheaHeroSlide(),
      const MaraPuntosHeroSlide(),
      MedicPlusHeroSlide(onTap: onMedicPlusTap),
    ];

    final heroBanners = this.heroBanners
        .where((b) {
          final t = b.title.toLowerCase();
          // Evitar duplicar Cashea / club si ya van en leading
          return !t.contains('marapuntos') &&
              !t.contains('club farma') &&
              !t.contains('cashea') &&
              !t.contains('medic plus') &&
              !t.contains('medicplus') &&
              !t.contains('salud360') &&
              !t.contains('salud 360') &&
              !t.contains('dog plus') &&
              !t.contains('padel') &&
              !t.contains('pádel') &&
              !t.contains('prueba');
        })
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BannerCarousel(
          leadingSlides: leadingSlides,
          banners: heroBanners,
        ),
        if (bannersLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MaraColors.green,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
