import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/mara_network_image.dart';
import '../../home/domain/models/catalog_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return AdminShell(
      title: 'Productos',
      currentIndex: 1,
      floatingActionButton: AdminFab(
        label: 'Nuevo',
        icon: Icons.add_rounded,
        color: MaraColors.green,
        onPressed: () => context.go('/admin/products/new'),
      ),
      child: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (products) {
          if (products.isEmpty) {
            return AdminEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'Catálogo vacío',
              subtitle: 'Crea tu primer producto con imagen, precio y stock.',
              action: FilledButton(
                onPressed: () => context.go('/admin/products/new'),
                child: const Text('Crear producto'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminProductsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: products.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AdminHeroBanner(
                    title: '${products.length} productos en catálogo',
                    subtitle: 'Edita precios, stock, imágenes o elimina artículos de la tienda.',
                  );
                }
                return _AdminProductTile(product: products[index - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminProductTile extends ConsumerWidget {
  const _AdminProductTile({required this.product});

  final Product product;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quitar "${product.name}" de la tienda?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MaraColors.rose),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteProduct(product.id);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminStatsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado'), backgroundColor: MaraColors.green),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final narrow = MediaQuery.sizeOf(context).width < 520;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => context.go('/admin/products/${product.id}/edit'),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: [
              BoxShadow(
                color: MaraColors.navy.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _ProductThumb(product: product),
                        const SizedBox(width: 12),
                        Expanded(child: _ProductInfo(product: product)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProductActions(product: product, onDelete: () => _delete(context, ref)),
                  ],
                )
              : Row(
                  children: [
                    _ProductThumb(product: product),
                    const SizedBox(width: 14),
                    Expanded(child: _ProductInfo(product: product)),
                    _ProductActions(product: product, onDelete: () => _delete(context, ref)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        height: 76,
        child: product.imageUrl != null && product.imageUrl!.isNotEmpty
            ? MaraNetworkImage(imageUrl: product.imageUrl!, width: 76, height: 76, fit: BoxFit.cover)
            : Container(color: MaraColors.lightBlue, child: const Icon(Icons.image_outlined)),
      ),
    );
  }
}

class _ProductInfo extends StatelessWidget {
  const _ProductInfo({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(product.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 2),
        Text('${product.sku} · ${product.category.name}', style: const TextStyle(color: MaraColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('\$${product.finalPrice.toStringAsFixed(2)}', style: const TextStyle(color: MaraColors.navy, fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(width: 10),
            AdminStatusBadge(
              active: product.inStock,
              activeLabel: '${product.stock} u.',
              inactiveLabel: 'Agotado',
            ),
          ],
        ),
      ],
    );
  }
}

class _ProductActions extends StatelessWidget {
  const _ProductActions({required this.product, required this.onDelete});
  final Product product;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () => context.go('/admin/products/${product.id}/edit'),
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded, color: MaraColors.rose),
        ),
      ],
    );
  }
}
