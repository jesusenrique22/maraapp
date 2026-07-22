import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import 'home_header.dart';
import 'product_detail_sheet.dart';

class ProductCard extends StatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.compact = false,
    this.onAdd,
  });

  final Product product;
  final bool compact;
  final VoidCallback? onAdd;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final imgH = widget.compact ? 148.0 : 168.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => ProductDetailSheet.show(context, widget.product),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A6E).withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Imagen Full-Bleed con badge encima ───
              SizedBox(
                height: imgH,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen ocupa todo el espacio
                    ProductImage(
                      imageUrl: widget.product.imageUrl,
                      categorySlug: widget.product.category.slug,
                      borderRadius: BorderRadius.zero,
                    ),
                    // Overlay si agotado
                    if (!widget.product.inStock)
                      Container(
                        color: Colors.white.withValues(alpha: 0.72),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: MaraColors.rose,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'AGOTADO',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    // Badge de descuento: esquina superior izquierda
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: _DiscountBadge(
                          percent: widget.product.discountPercent!,
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Detalles ───
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría
                      Text(
                        widget.product.category.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: MaraColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Nombre
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.3,
                          color: MaraColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      // Precio + botón "+" en la misma fila
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '\$${widget.product.finalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: MaraColors.green,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                if (widget.product.hasDiscount)
                                  Text(
                                    '\$${widget.product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: MaraColors.textTertiary,
                                      decoration: TextDecoration.lineThrough,
                                      fontSize: 11.5,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (widget.product.inStock)
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                widget.onAdd?.call();
                              },
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: MaraColors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: MaraColors.green
                                          .withValues(alpha: 0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: MaraColors.green,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$percent%',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }
}
