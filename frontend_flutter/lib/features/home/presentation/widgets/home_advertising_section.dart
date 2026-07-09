import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'banner_carousel.dart';
import 'delivery_info_strip.dart';
import 'dog_plus_hero_slide.dart';
import 'mara_puntos_hero_slide.dart';
import 'medic_plus_hero_slide.dart';

/// Carrusel unificado: MaraPuntos, Dog Plus, Medic Plus y banners del catálogo.
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

  PromoBanner? _deliveryBanner() {
    for (final banner in stripBanners) {
      final text = '${banner.title} ${banner.subtitle ?? ''}'.toLowerCase();
      if (text.contains('delivery') ||
          text.contains('envío') ||
          text.contains('envio')) {
        return banner;
      }
    }
    return stripBanners.isNotEmpty ? stripBanners.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final delivery = _deliveryBanner();

    final leadingSlides = <Widget>[
      const MaraPuntosHeroSlide(),
      const DogPlusHeroSlide(),
      MedicPlusHeroSlide(onTap: onMedicPlusTap),
    ];

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
                child: CircularProgressIndicator(strokeWidth: 2, color: MaraColors.navyMid),
              ),
            ),
          ),
        DeliveryInfoStrip(banner: delivery),
      ],
    );
  }
}
