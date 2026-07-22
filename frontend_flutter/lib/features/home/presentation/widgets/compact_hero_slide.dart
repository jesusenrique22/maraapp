import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'promo_cta_button.dart';

/// Slide compacto para el carrusel hero — evita overflow y mantiene estilo uniforme.
class CompactHeroSlide extends StatelessWidget {
  const CompactHeroSlide({
    super.key,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.emoji,
    this.ctaLabel,
    this.ctaLeadingIcon,
    this.onTap,
  });

  factory CompactHeroSlide.fromBanner(PromoBanner banner) {
    final bg = _parseColor(banner.backgroundColor, MaraColors.green);
    final isLight = bg.computeLuminance() > 0.55;
    return CompactHeroSlide(
      badge: banner.badgeText ?? 'PROMO',
      title: banner.title,
      subtitle: banner.subtitle ?? '',
      colors: isLight
          ? [bg, Color.lerp(bg, Colors.white, 0.08)!, Color.lerp(bg, Colors.black, 0.06)!]
          : [bg, _darken(bg, 0.12), _darken(bg, 0.22)],
      ctaLabel: banner.buttonText,
    );
  }

  final String badge;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final String? emoji;
  final String? ctaLabel;
  final IconData? ctaLeadingIcon;
  final VoidCallback? onTap;

  static Color _parseColor(String hex, Color fallback) {
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return fallback;
  }

  static Color _darken(Color color, double amount) {
    return Color.lerp(color, Colors.black, amount) ?? color;
  }

  @override
  Widget build(BuildContext context) {
    final accent = colors.first;
    final isLight = accent.computeLuminance() > 0.55;
    final titleColor = isLight ? Colors.black : Colors.white;
    final muted = isLight
        ? Colors.black.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.88);
    final ctaAccent = isLight ? Colors.black : MaraColors.green;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: (isLight ? Colors.black : accent).withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: colors.length >= 3
                        ? colors
                        : [colors.first, _darken(colors.first, 0.15)],
                  ),
                ),
              ),
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isLight ? Colors.black : Colors.white)
                        .withValues(alpha: 0.07),
                  ),
                ),
              ),
              if (emoji != null)
                Positioned(
                  right: 18,
                  bottom: 14,
                  child: Transform.rotate(
                    angle: -0.1,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji!, style: const TextStyle(fontSize: 32)),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 18, emoji != null ? 90 : 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Badge(label: badge, onLight: isLight),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (ctaLabel != null) ...[
                      const SizedBox(height: 10),
                      PromoCtaButton(
                        label: ctaLabel!,
                        accentColor: ctaAccent,
                        leadingIcon: ctaLeadingIcon,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.onLight = false});

  final String label;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onLight
            ? Colors.black.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: onLight
              ? Colors.black.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onLight ? Colors.black : Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
