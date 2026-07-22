import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/mara_theme.dart';
import '../../../branches/domain/branch_models.dart';
import '../../../branches/providers/branches_provider.dart';
import '../../data/catalog_repository.dart';
import '../../domain/models/catalog_models.dart';
import '../widgets/home_header.dart';
import '../../providers/cart_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _availabilityProvider =
    FutureProvider.family<List<dynamic>, String>((ref, productId) {
  return ref.read(apiClientProvider).getList('/products/$productId/availability');
});

final _relatedProductsProvider =
    FutureProvider.family<List<Product>, _RelatedQuery>((ref, q) async {
  final branchId = ref.watch(selectedBranchProvider)?.id;
  final all = await ref
      .read(catalogRepositoryProvider)
      .fetchProducts(categorySlug: q.categorySlug, branchId: branchId);
  return all.where((p) => p.id != q.excludeId).take(8).toList();
});

class _RelatedQuery {
  const _RelatedQuery({required this.categorySlug, required this.excludeId});
  final String categorySlug;
  final String excludeId;

  @override
  bool operator ==(Object o) =>
      o is _RelatedQuery &&
      o.categorySlug == categorySlug &&
      o.excludeId == excludeId;

  @override
  int get hashCode => Object.hash(categorySlug, excludeId);
}

// ─── Entry point ─────────────────────────────────────────────────────────────

class ProductDetailSheet extends ConsumerStatefulWidget {
  const ProductDetailSheet({super.key, required this.product});

  final Product product;

  static Future<void> show(BuildContext context, Product product) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => ProductDetailSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductDetailSheet> createState() => _State();
}

class _State extends ConsumerState<ProductDetailSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int _branchStock(Branch? branch, List<dynamic>? av) {
    if (av == null) return widget.product.stock;
    if (branch == null) return widget.product.stock;
    try {
      final m = av.firstWhere(
        (e) => e['branch']['id'] == branch.id,
        orElse: () => null,
      );
      return m != null ? (m['stock'] as num).toInt() : 0;
    } catch (_) {
      return 0;
    }
  }

  Color _accent(String slug) => switch (slug) {
        'farmacia' => MaraColors.green,
        'panaderia' => MaraColors.amber,
        'mascotas' => MaraColors.violet,
        _ => MaraColors.navyMid,
      };

  @override
  Widget build(BuildContext context) {
    final branch = ref.watch(selectedBranchProvider);
    final avAsync = ref.watch(_availabilityProvider(widget.product.id));
    final stock = _branchStock(branch, avAsync.valueOrNull);
    final inStock = stock > 0;
    final accent = _accent(widget.product.category.slug);

    if (_qty > stock && inStock) _qty = stock.clamp(1, stock);

    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          // ── Drag pill ──────────────────────────────────────────────────────
          const _Pill(),

          // ── Hero header (imagen + datos clave) ─────────────────────────────
          _HeroHeader(
            product: widget.product,
            accent: accent,
            branch: branch,
            stock: stock,
            inStock: inStock,
          ),

          // ── Tabs ───────────────────────────────────────────────────────────
          _TabBar(controller: _tabs),

          // ── Tab content ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _SpecsPage(product: widget.product),
                _BranchPage(avAsync: avAsync),
              ],
            ),
          ),

          // ── Purchase bar ───────────────────────────────────────────────────
          _PurchaseBar(
            product: widget.product,
            qty: _qty,
            inStock: inStock,
            maxQty: stock,
            accent: accent,
            onDec: () { if (_qty > 1) setState(() => _qty--); },
            onInc: () { if (_qty < stock) setState(() => _qty++); },
            onBuy: () {
              HapticFeedback.mediumImpact();
              final err = ref
                  .read(cartProvider.notifier)
                  .addProduct(widget.product, amount: _qty);
              if (err != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err), backgroundColor: MaraColors.rose));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${widget.product.name} agregado al carrito'),
                backgroundColor: MaraColors.green,
                duration: const Duration(seconds: 1),
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill
// ─────────────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.product,
    required this.accent,
    required this.branch,
    required this.stock,
    required this.inStock,
  });

  final Product product;
  final Color accent;
  final Branch? branch;
  final int stock;
  final bool inStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProductImage(
                  imageUrl: product.imageUrl,
                  categorySlug: product.category.slug,
                  borderRadius: BorderRadius.zero,
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        color: MaraColors.navyAccent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${product.discountPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Info column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill
                _Badge(
                  text: product.category.name.toUpperCase(),
                  color: accent,
                  fontSize: 9,
                  letterSpacing: 0.7,
                ),
                const SizedBox(height: 7),

                // Name
                Text(
                  product.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: MaraColors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),

                // Price row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.finalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: MaraColors.navy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (product.hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: MaraColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Stock chip
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: inStock ? MaraColors.green : MaraColors.rose,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        inStock
                            ? 'Disponible · $stock uds${branch != null ? " en ${branch!.name}" : ""}'
                            : 'Agotado${branch != null ? " en ${branch!.name}" : ""}',
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: inStock ? MaraColors.green : MaraColors.rose,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),
                Text(
                  'SKU ${product.sku}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: MaraColors.textTertiary,
                    fontWeight: FontWeight.w500,
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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.color,
    this.fontSize = 10.0,
    this.letterSpacing = 0.3,
  });

  final String text;
  final Color color;
  final double fontSize;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBar
// ─────────────────────────────────────────────────────────────────────────────
class _TabBar extends StatelessWidget {
  const _TabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        labelColor: MaraColors.navyAccent,
        unselectedLabelColor: MaraColors.textTertiary,
        indicatorColor: MaraColors.navyAccent,
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Especificaciones'),
          Tab(text: 'Disponibilidad'),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Especificaciones + Productos relacionados
// ─────────────────────────────────────────────────────────────────────────────
class _SpecsPage extends ConsumerWidget {
  const _SpecsPage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatedAsync = ref.watch(_relatedProductsProvider(
      _RelatedQuery(
        categorySlug: product.category.slug,
        excludeId: product.id,
      ),
    ));

    final specs = _buildSpecs(product);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── Descripción ────────────────────────────────────────────────────
        _Section(
          title: 'Descripción',
          child: Text(
            product.description ?? _fallbackDesc(product.category.slug),
            style: const TextStyle(
              fontSize: 13,
              color: MaraColors.textSecondary,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // ── Especificaciones ───────────────────────────────────────────────
        if (specs.isNotEmpty) ...[
          _Section(
            title: 'Ficha técnica',
            child: Column(
              children: specs.asMap().entries.map((e) {
                final isLast = e.key == specs.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              e.value['label']!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: MaraColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value['value']!,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: MaraColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                          height: 1, color: Color(0xFFF1F5F9)),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
        ],

        // ── Productos relacionados ─────────────────────────────────────────
        relatedAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(MaraColors.navyMid),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (related) {
            if (related.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Text(
                        'Productos similares',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: MaraColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${related.length} productos',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: MaraColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 222,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: related.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      return _RelatedCard(
                        product: related[i],
                        onTap: () {
                          Navigator.pop(context);
                          Future.delayed(
                            const Duration(milliseconds: 200),
                            () => ProductDetailSheet.show(context, related[i]),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  List<Map<String, String>> _buildSpecs(Product p) {
    return switch (p.category.slug) {
      'farmacia' => [
          {'label': 'Categoría', 'value': 'Medicamentos'},
          {'label': 'Uso', 'value': 'Adulto'},
          {'label': 'Requiere receta', 'value': 'No'},
          {'label': 'Presentación', 'value': 'Caja / Blíster'},
          {'label': 'Control sanitario', 'value': 'Supervisado'},
          {'label': 'SKU', 'value': p.sku},
        ],
      'panaderia' => [
          {'label': 'Categoría', 'value': 'Panadería artesanal'},
          {'label': 'Producción', 'value': 'Diaria'},
          {'label': 'Conservación', 'value': 'Temperatura ambiente'},
          {'label': 'Ingredientes', 'value': 'Harina, levadura, agua, sal'},
          {'label': 'SKU', 'value': p.sku},
        ],
      'mascotas' => [
          {'label': 'Categoría', 'value': 'Mascotas'},
          {'label': 'Especie', 'value': 'Perro / Gato'},
          {'label': 'Etapa vital', 'value': 'Adulto'},
          {'label': 'Presentación', 'value': 'Bolsa sellada'},
          {'label': 'SKU', 'value': p.sku},
        ],
      _ => [
          {'label': 'Categoría', 'value': p.category.name},
          {'label': 'SKU', 'value': p.sku},
        ],
    };
  }

  String _fallbackDesc(String slug) {
    return switch (slug) {
      'farmacia' =>
        'Medicamento que cumple con rigurosos estándares de calidad y control sanitario. Siga siempre la dosificación indicada por su médico y evite la automedicación.',
      'panaderia' =>
        'Horneado artesanalmente a diario con ingredientes de primera calidad. Consúmalo en el mismo día para una mejor experiencia de sabor y frescura.',
      'mascotas' =>
        'Formulado especialmente para mantener a su mascota saludable, activa y con un pelaje brillante, con ingredientes de la más alta calidad nutricional.',
      _ =>
        'Producto de alta calidad seleccionado para el catálogo Farma Express. Garantía de frescura y satisfacción en cada pedido.',
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Related product card (mini)
// ─────────────────────────────────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  const _RelatedCard({required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  Color _accent(String slug) => switch (slug) {
        'farmacia' => MaraColors.green,
        'panaderia' => MaraColors.amber,
        'mascotas' => MaraColors.violet,
        _ => MaraColors.navyMid,
      };

  @override
  Widget build(BuildContext context) {
    final accent = _accent(product.category.slug);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image area
            SizedBox(
              height: 112,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ProductImage(
                        imageUrl: product.imageUrl,
                        categorySlug: product.category.slug,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                        decoration: BoxDecoration(
                          color: MaraColors.navyAccent,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${product.discountPercent}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: MaraColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '\$${product.finalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: MaraColors.navy,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: accent,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Sucursales
// ─────────────────────────────────────────────────────────────────────────────
class _BranchPage extends StatelessWidget {
  const _BranchPage({
    required this.avAsync,
  });

  final AsyncValue<List<dynamic>> avAsync;

  @override
  Widget build(BuildContext context) {
    return avAsync.when(
      loading: () => const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(MaraColors.navyMid),
          ),
        ),
      ),
      error: (_, __) => _errorView(),
      data: (av) {
        // Group by city
        final Map<String, List<dynamic>> byCityMap = {};
        for (final item in av) {
          final city = item['branch']['city'] as String? ?? 'Otros';
          byCityMap.putIfAbsent(city, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          children: [
            // Informative pickup banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: MaraColors.navyAccent, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Solo Retiro en Tienda (Pickup)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Actualmente los pedidos de la tienda son exclusivamente para retirar en sucursal. No disponemos de servicio de delivery por los momentos.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: MaraColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            _LegendRow(),
            const SizedBox(height: 14),

            ...byCityMap.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: MaraColors.textTertiary,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: entry.value.asMap().entries.map((e) {
                        final isLast = e.key == entry.value.length - 1;
                        return _BranchTile(
                          item: e.value,
                          showDivider: !isLast,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  Widget _errorView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: MaraColors.textTertiary),
            SizedBox(height: 12),
            Text(
              'No se pudo cargar la disponibilidad',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: MaraColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _Dot(color: MaraColors.green, label: 'Disponible'),
          const SizedBox(width: 18),
          _Dot(color: MaraColors.amber, label: 'Poca disp.'),
          const SizedBox(width: 18),
          _Dot(color: MaraColors.rose, label: 'Agotado'),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: MaraColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _BranchTile extends StatelessWidget {
  const _BranchTile({
    required this.item,
    required this.showDivider,
  });

  final dynamic item;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final stock = (item['stock'] as num).toInt();
    final name = item['branch']['name'] as String;
    final address = item['branch']['address'] as String? ?? '';
    final hours = item['branch']['openingHours'] as String?;

    Color dot;
    String label;
    if (stock > 5) {
      dot = MaraColors.green;
      label = 'Disponible · $stock unidades';
    } else if (stock > 0) {
      dot = MaraColors.amber;
      label = 'Poca disponibilidad · $stock unidades';
    } else {
      dot = MaraColors.rose;
      label = 'Agotado';
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dot
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dot.withValues(alpha: 0.35),
                        blurRadius: 5,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: MaraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MaraColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hours != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 10, color: MaraColors.textTertiary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              hours,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: MaraColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 5),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: dot,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 37, color: Color(0xFFF1F5F9)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase bar
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseBar extends StatelessWidget {
  const _PurchaseBar({
    required this.product,
    required this.qty,
    required this.inStock,
    required this.maxQty,
    required this.accent,
    required this.onDec,
    required this.onInc,
    required this.onBuy,
  });

  final Product product;
  final int qty;
  final bool inStock;
  final int maxQty;
  final Color accent;
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onBuy;

  double get totalCost2 => product.finalPrice * qty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        children: [
          if (inStock) ...[
            // Qty stepper
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _StepBtn(
                      icon: Icons.remove_rounded,
                      enabled: qty > 1,
                      onTap: onDec),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: MaraColors.textPrimary,
                      ),
                    ),
                  ),
                  _StepBtn(
                      icon: Icons.add_rounded,
                      enabled: qty < maxQty,
                      onTap: onInc),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // Buy button
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: inStock ? MaraColors.green : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: inStock ? onBuy : null,
                child: Text(
                  inStock
                      ? 'Agregar  ·  \$${totalCost2.toStringAsFixed(2)}'
                      : 'Agotado en esta sucursal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(
          icon,
          size: 18,
          color: enabled ? MaraColors.textPrimary : MaraColors.textTertiary,
        ),
      ),
    );
  }
}
