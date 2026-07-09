import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';

class PromoStripRow extends StatelessWidget {
  const PromoStripRow({
    super.key,
    required this.banners,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 0),
  });

  final List<PromoBanner> banners;
  final EdgeInsetsGeometry padding;

  Color _parseColor(String hex, Color fallback) {
    final value = hex.replaceAll('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    final items = banners.take(2).toList();

    return Padding(
      padding: padding,
      child: Row(
        children: List.generate(items.length, (index) {
          final banner = items[index];
          final bg = _parseColor(banner.backgroundColor, MaraColors.green);

          final gradients = [
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MaraColors.green, const Color(0xFF007A46)],
            ),
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [MaraColors.navyMid, const Color(0xFF1E40AF)],
            ),
          ];

          final gradient = index < gradients.length ? gradients[index] : MaraColors.gradientGreen;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 0 && items.length > 1 ? 10 : 0),
              child: _PromoCard(banner: banner, gradient: gradient, bg: bg),
            ),
          );
        }),
      ),
    );
  }
}

class _PromoCard extends StatefulWidget {
  const _PromoCard({
    required this.banner,
    required this.gradient,
    required this.bg,
  });

  final PromoBanner banner;
  final LinearGradient gradient;
  final Color bg;

  @override
  State<_PromoCard> createState() => _PromoCardState();
}

class _PromoCardState extends State<_PromoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _anim.forward();
      },
      onTapUp: (_) => _anim.reverse(),
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: widget.bg.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -15,
                bottom: -25,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (banner.badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          banner.badgeText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.15,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (banner.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        banner.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(child: const SizedBox()),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
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
