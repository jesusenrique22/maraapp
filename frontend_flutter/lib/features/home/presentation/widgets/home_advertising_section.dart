import 'package:flutter/material.dart';

import '../../domain/models/catalog_models.dart';
import 'banner_carousel.dart';
import 'compact_hero_slide.dart';
import 'delivery_info_strip.dart';
import 'dog_plus_hero_slide.dart';
import 'medic_plus_hero_slide.dart';

/// Carrusel unificado: Dog Plus, farmacia, Medic Plus y banners del catálogo.
class HomeAdvertisingSection extends StatelessWidget {
  const HomeAdvertisingSection({
    super.key,
    required this.heroBanners,
    this.stripBanners = const [],
    required this.onMedicPlusTap,
  });

  final List<PromoBanner> heroBanners;
  final List<PromoBanner> stripBanners;
  final VoidCallback onMedicPlusTap;

  PromoBanner? _pharmacyBanner() {
    for (final banner in stripBanners) {
      final text = '${banner.title} ${banner.subtitle ?? ''}'.toLowerCase();
      if (text.contains('farmacia') || text.contains('ahorrar')) {
        return banner;
      }
    }
    return stripBanners.isNotEmpty ? stripBanners.last : null;
  }

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
    final pharmacy = _pharmacyBanner();
    final delivery = _deliveryBanner();

    final leadingSlides = <Widget>[
      const DogPlusHeroSlide(),
      if (pharmacy != null) CompactHeroSlide.fromBanner(pharmacy),
      MedicPlusHeroSlide(onTap: onMedicPlusTap),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BannerCarousel(
          leadingSlides: leadingSlides,
          banners: heroBanners,
        ),
        DeliveryInfoStrip(banner: delivery),
      ],
    );
  }
}
