import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'banner_carousel.dart';
import 'dog_plus_hero_slide.dart';
import 'mara_puntos_hero_slide.dart';
import 'medic_plus_hero_slide.dart';
import 'padel_info_strip.dart';

/// Carrusel unificado: MaraPuntos, Dog Plus, Medic Plus + strip de pádel.
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

  PromoBanner? _padelBanner() {
    for (final banner in stripBanners) {
      final text = '${banner.title} ${banner.subtitle ?? ''}'.toLowerCase();
      if (text.contains('padel') ||
          text.contains('pádel') ||
          text.contains('cancha') ||
          text.contains('agenda')) {
        return banner;
      }
    }
    return stripBanners.isNotEmpty ? stripBanners.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final padel = _padelBanner();

    final leadingSlides = <Widget>[
      const MaraPuntosHeroSlide(),
      const DogPlusHeroSlide(),
      MedicPlusHeroSlide(onTap: onMedicPlusTap),
    ];

    // Evita duplicar MaraPuntos si también viene desde la API.
    final heroBanners = this.heroBanners
        .where((b) => !b.title.toLowerCase().contains('marapuntos'))
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
                  color: MaraColors.navyMid,
                ),
              ),
            ),
          ),
        PadelInfoStrip(banner: padel),
      ],
    );
  }
}
