import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../../orders/domain/order_models.dart';

class OrderSuccessSheet {
  static Future<void> show(BuildContext context, Order order) {
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Compra exitosa! Pedido ${order.orderNumber}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: MaraColors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderSuccessContent(order: order),
    );
  }
}

class _OrderSuccessContent extends StatelessWidget {
  const _OrderSuccessContent({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: MaraColors.green.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: MaraColors.green,
              size: 56,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '¡Compra exitosa!',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 26,
              color: MaraColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu pedido fue registrado correctamente.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MaraColors.textSecondary.withValues(alpha: 0.95),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MaraColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _Row(label: 'Pedido', value: order.orderNumber),
                const SizedBox(height: 10),
                _Row(
                  label: 'Total',
                  value: '\$${order.total.toStringAsFixed(2)}',
                  bold: true,
                ),
                const SizedBox(height: 10),
                _Row(label: 'Estado', value: order.statusLabel),
                if (order.branch != null) ...[
                  const SizedBox(height: 10),
                  _Row(label: 'Retiro', value: order.branch!.name),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Seguir comprando',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: MaraColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
              color: MaraColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}
