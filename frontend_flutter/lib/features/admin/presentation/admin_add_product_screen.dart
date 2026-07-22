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

class AdminAddProductScreen extends ConsumerStatefulWidget {
  const AdminAddProductScreen({super.key});

  @override
  ConsumerState<AdminAddProductScreen> createState() =>
      _AdminAddProductScreenState();
}

class _AdminAddProductScreenState extends ConsumerState<AdminAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '10');
  final _discountController = TextEditingController();

  String? _categoryId;
  bool _isFeatured = false;
  bool _submitting = false;
  bool _pickingImage = false;

  PickedImage? _pickedImage;
  String? _uploadStatus;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);

    try {
      final file = await pickProductImage();

      if (file == null) return;

      setState(() {
        _pickedImage = file;
        _uploadStatus = null;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el selector de imágenes')),
      );
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
      _uploadStatus = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }

    // Imagen opcional: si no hay, usa placeholder Farma Express
    const placeholderImage =
        'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=600&auto=format&fit=crop';

    setState(() {
      _submitting = true;
      _uploadStatus =
          _pickedImage != null ? 'Subiendo imagen...' : 'Creando producto...';
    });

    try {
      String imageUrl = placeholderImage;
      if (_pickedImage != null) {
        imageUrl = await ref.read(adminRepositoryProvider).uploadProductImage(
              fileName: _pickedImage!.name,
              bytes: _pickedImage!.bytes,
              mimeType: _pickedImage!.mimeType,
            );
        if (!mounted) return;
        setState(() => _uploadStatus = 'Creando producto...');
      }

      final input = CreateProductInput(
        sku: _skuController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        categoryId: _categoryId!,
        imageUrl: imageUrl,
        initialStock: int.tryParse(_stockController.text.trim()),
        discountPercent: int.tryParse(_discountController.text.trim()),
        isFeatured: _isFeatured,
      );

      await ref.read(adminRepositoryProvider).createProduct(input);

      ref.invalidate(adminProductsProvider);
      ref.invalidate(adminStatsProvider);
      ref.invalidate(productsProvider(const ProductQuery()));
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(categoriesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Producto creado y visible en la tienda'),
          backgroundColor: MaraColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/admin/products');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadStatus = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return AdminShell(
      title: 'Nuevo producto',
      currentIndex: 1,
      child: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (categories) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminSectionCard(
                      title: 'Información básica',
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 560;

                              if (narrow) {
                                return Column(
                                  children: [
                                    TextFormField(
                                      controller: _skuController,
                                      decoration: const InputDecoration(
                                        labelText: 'SKU',
                                        hintText: 'PAN-010',
                                        helperText: 'Debe ser único en el catálogo',
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 2 ? 'Requerido' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre del producto',
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 2 ? 'Requerido' : null,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _skuController,
                                      decoration: const InputDecoration(
                                        labelText: 'SKU',
                                        hintText: 'PAN-010',
                                        helperText: 'Debe ser único en el catálogo',
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 2 ? 'Requerido' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _nameController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nombre del producto',
                                      ),
                                      validator: (v) =>
                                          v == null || v.length < 2 ? 'Requerido' : null,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _categoryId,
                            decoration: const InputDecoration(
                              labelText: 'Categoría',
                            ),
                            items: categories
                                .map(
                                  (Category c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _categoryId = value),
                            validator: (v) => v == null ? 'Selecciona categoría' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminSectionCard(
                      title: 'Precio, stock y promoción',
                      child: Column(
                        children: [
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final narrow = constraints.maxWidth < 560;

                              final priceField = TextFormField(
                                controller: _priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Precio',
                                  prefixText: '\$ ',
                                ),
                                validator: (v) {
                                  if (double.tryParse(v ?? '') == null) {
                                    return 'Precio inválido';
                                  }
                                  return null;
                                },
                              );

                              final stockField = TextFormField(
                                controller: _stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stock inicial',
                                ),
                              );

                              final discountField = TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Descuento',
                                  suffixText: '%',
                                ),
                              );

                              if (narrow) {
                                return Column(
                                  children: [
                                    priceField,
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(child: stockField),
                                        const SizedBox(width: 16),
                                        Expanded(child: discountField),
                                      ],
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: priceField),
                                  const SizedBox(width: 16),
                                  Expanded(child: stockField),
                                  const SizedBox(width: 16),
                                  Expanded(child: discountField),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Destacar en "Recomendados"'),
                            subtitle: const Text(
                              'Aparece en la sección principal del Home',
                            ),
                            value: _isFeatured,
                            activeThumbColor: MaraColors.green,
                            onChanged: (value) => setState(() => _isFeatured = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminSectionCard(
                      title: 'Imagen del producto',
                      child: AdminProductImagePicker(
                        pickedImage: _pickedImage,
                        picking: _pickingImage,
                        onPick: _pickImage,
                        onClear: _clearImage,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: _submitting ? null : () => context.go('/admin/products'),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : _submit,
                            icon: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded),
                            label: Text(
                              _uploadStatus ??
                                  (_submitting ? 'Guardando...' : 'Publicar producto'),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: MaraColors.green,
                              minimumSize: const Size.fromHeight(52),
                            ),
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
