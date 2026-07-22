import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/mara_theme.dart';

class MaraNetworkImage extends StatelessWidget {
  const MaraNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallback,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      final fallbackWidget = fallback ?? _defaultFallback();
      if (borderRadius == null) return fallbackWidget;
      return ClipRRect(borderRadius: borderRadius!, child: fallbackWidget);
    }

    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      httpHeaders: const {'Accept': 'image/*'},
      placeholder: (_, _) => fallback ?? _defaultFallback(),
      errorWidget: (_, _, _) => fallback ?? _defaultFallback(),
    );

    if (borderRadius == null) return image;

    return ClipRRect(
      borderRadius: borderRadius!,
      child: image,
    );
  }

  Widget _defaultFallback() {
    return Container(
      width: width,
      height: height,
      color: MaraColors.lightBlue,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        color: MaraColors.navy.withValues(alpha: 0.35),
      ),
    );
  }
}
