import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';

/// Franja de pádel — reserva de cancha (próximamente).
class PadelInfoStrip extends StatelessWidget {
  const PadelInfoStrip({super.key, this.banner, this.onTap});

  final PromoBanner? banner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = banner?.title ?? 'MaraPadel · Reserva tu cancha';
    final subtitle =
        banner?.subtitle ?? 'Agenda tu partido · Próximamente en la app';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: MaraColors.navy.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.sports_tennis_rounded,
                color: Color(0xFF0284C7),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MaraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MaraColors.amberLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'PRÓX.',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB45309),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: MaraColors.textTertiary.withValues(alpha: 0.8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
