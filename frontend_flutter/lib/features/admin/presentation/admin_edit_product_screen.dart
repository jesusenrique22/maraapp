import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../home/data/catalog_repository.dart';
import '../../home/domain/models/catalog_models.dart';
import '../data/image_picker.dart';
import '../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_form_widgets.dart';
import 'widgets/admin_shell.dart';

class AdminEditProductScreen extends ConsumerStatefulWidget {
  const AdminEditProductScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends ConsumerState<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  String? _categoryId;
  String? _imageUrl;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _loading = true;
  bool _submitting = false;
  bool _pickingImage = false;
  PickedImage? _pickedImage;
  Product? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final products = await ref.read(adminRepositoryProvider).fetchProducts();
      final rawList = await ref.read(apiClientProvider).getList('/admin/products');
      final raw = rawList.cast<Map<String, dynamic>>().firstWhere(
            (p) => p['id'] == widget.productId,
          );
      final product = products.firstWhere((p) => p.id == widget.productId);

      _nameController.text = product.name;
      _descriptionController.text = product.description ?? '';
      _priceController.text = product.price.toStringAsFixed(2);
      _discountController.text = product.discountPercent?.toString() ?? '';
      _categoryId = product.category.id;
      _imageUrl = product.imageUrl;
      _isFeatured = raw['isFeatured'] as bool? ?? false;
      _isActive = raw['isActive'] as bool? ?? true;
      _product = product;
    } catch (_) {
      _product = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final file = await pickProductImage();
      if (file != null) setState(() => _pickedImage = file);
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) return;

    setState(() => _submitting = true);
    try {
      var imageUrl = _imageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref.read(adminRepositoryProvider).uploadProductImage(
              fileName: _pickedImage!.name,
              bytes: _pickedImage!.bytes,
              mimeType: _pickedImage!.mimeType,
            );
      }

      await ref.read(adminRepositoryProvider).updateProduct(
            widget.productId,
            UpdateProductInput(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: double.parse(_priceController.text.trim()),
              categoryId: _categoryId,
              imageUrl: imageUrl,
              discountPercent: int.tryParse(_discountController.text.trim()),
              isFeatured: _isFeatured,
              isActive: _isActive,
            ),
          );

      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(productsProvider(const ProductQuery()));
      ref.invalidate(featuredProductsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado'), backgroundColor: MaraColors.green),
      );
      context.go('/admin/products');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteProduct() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Quitar "${_product?.name}" de la tienda?'),
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
      await ref.read(adminRepositoryProvider).deleteProduct(widget.productId);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(productsProvider(const ProductQuery()));
      ref.invalidate(featuredProductsProvider);
      if (!mounted) return;
      context.go('/admin/products');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    if (_loading) {
      return const AdminShell(
        title: 'Editar producto',
        currentIndex: 1,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return AdminShell(
        title: 'Editar producto',
        currentIndex: 1,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Producto no encontrado'),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => context.go('/admin/products'), child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    return AdminShell(
      title: 'Editar producto',
      currentIndex: 1,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AdminSectionCard(
                      title: 'Información',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nombre'),
                            validator: (v) => v == null || v.length < 2 ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Descripción'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _categoryId,
                            decoration: const InputDecoration(labelText: 'Categoría'),
                            items: categories
                                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                .toList(),
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSectionCard(
                      title: 'Precio y visibilidad',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ '),
                                  validator: (v) => double.tryParse(v ?? '') == null ? 'Inválido' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _discountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'Descuento %'),
                                ),
                              ),
                            ],
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Destacado en home'),
                            value: _isFeatured,
                            onChanged: (v) => setState(() => _isFeatured = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Visible en tienda'),
                            value: _isActive,
                            onChanged: (v) => setState(() => _isActive = v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AdminSectionCard(
                      title: 'Imagen',
                      child: AdminProductImagePicker(
                        pickedImage: _pickedImage,
                        picking: _pickingImage,
                        onPick: _pickImage,
                        onClear: () => setState(() {
                          _pickedImage = null;
                          _imageUrl = null;
                        }),
                      ),
                    ),
                    if (_pickedImage == null && _imageUrl != null && _imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(_imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _submitting ? null : _deleteProduct,
                          style: OutlinedButton.styleFrom(foregroundColor: MaraColors.rose),
                          child: const Text('Eliminar'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : _save,
                            style: FilledButton.styleFrom(
                              backgroundColor: MaraColors.green,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: Text(_submitting ? 'Guardando...' : 'Guardar cambios'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
