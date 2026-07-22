import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import 'promo_cta_button.dart';

/// Banner promocional de Medic Plus para la zona de publicidad del home.
class MedicPlusPromoBanner extends StatelessWidget {
  const MedicPlusPromoBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: MaraColors.gradientGreen,
          boxShadow: [
            BoxShadow(
              color: MaraColors.green.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MEDIC PLUS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Medic Plus:\nConsultas Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Videollamada con especialistas y receta digital desde Farma Express.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const PromoCtaButton(
                          label: 'Consultar ahora',
                          accentColor: MaraColors.green,
                          leadingIcon: Icons.video_camera_front_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Transform.rotate(
                    angle: -0.12,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text('👨‍⚕️', style: TextStyle(fontSize: 28)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
