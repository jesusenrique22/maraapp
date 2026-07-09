import 'package:flutter/material.dart';

/// Botón CTA unificado para todos los banners de publicidad.
class PromoCtaButton extends StatelessWidget {
  const PromoCtaButton({
    super.key,
    required this.label,
    required this.accentColor,
    this.leadingIcon,
    this.showShadow = false,
  });

  static const double height = 38;
  static const double width = 148;

  final String label;
  final Color accentColor;
  final IconData? leadingIcon;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: accentColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          if (leadingIcon == null) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
          ],
        ],
      ),
    );
  }
}
