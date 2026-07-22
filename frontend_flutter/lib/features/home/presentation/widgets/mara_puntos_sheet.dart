import 'package:flutter/material.dart';

import '../../../../core/config/brand_config.dart';
import '../../../../core/theme/mara_theme.dart';

/// Detalle del programa de puntos (próximamente).
class MaraPuntosSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _MaraPuntosSheetBody(),
    );
  }
}

class _MaraPuntosSheetBody extends StatelessWidget {
  const _MaraPuntosSheetBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: MaraColors.gradientViolet,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            BrandConfig.loyaltyName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: MaraColors.greenLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'ACTIVO',
              style: TextStyle(
                color: MaraColors.greenDark,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '¡El club de beneficios de Farma Express ya está aquí! '
            'Suma puntos en farmacia, panadería, charcutería y más.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MaraColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          const _BenefitRow(
            icon: Icons.shopping_bag_outlined,
            title: 'Tu primera compra',
            subtitle: '¡Recibe el doble de puntos en tu primer pedido!',
          ),
          const _BenefitRow(
            icon: Icons.stars_rounded,
            title: 'Suma puntos',
            subtitle: 'Obtén 1 punto por cada \$1 de compra',
          ),
          const _BenefitRow(
            icon: Icons.redeem_outlined,
            title: 'Canjea descuentos',
            subtitle: 'Usa tus puntos en el checkout para pagar menos',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MaraColors.violetLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: MaraColors.violet),
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
                    color: MaraColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MaraColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
