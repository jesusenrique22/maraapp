import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'compact_hero_slide.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.banners,
    this.leadingSlides = const [],
  });

  final List<PromoBanner> banners;
  final List<Widget> leadingSlides;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _autoPlay;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    final total = widget.leadingSlides.length + widget.banners.length;
    if (total <= 1) return;

    _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || total == 0) return;
      final next = (_current + 1) % total;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.leadingSlides.length + widget.banners.length;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: total,
            itemBuilder: (context, index) {
              if (index < widget.leadingSlides.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: widget.leadingSlides[index],
                );
              }

              final banner = widget.banners[index - widget.leadingSlides.length];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: CompactHeroSlide.fromBanner(banner),
              );
            },
          ),
        ),
        if (total > 1) ...[
          const SizedBox(height: 14),
          AnimatedSmoothIndicator(
            activeIndex: _current,
            count: total,
            effect: ExpandingDotsEffect(
              dotHeight: 6,
              dotWidth: 8,
              expansionFactor: 4,
              activeDotColor: MaraColors.navyMid,
              dotColor: MaraColors.navyMid.withValues(alpha: 0.15),
            ),
          ),
        ],
      ],
    );
  }
}
