import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/mara_network_image.dart';
import '../../home/data/catalog_repository.dart';
import '../data/image_picker.dart';
import '../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminBannersScreen extends ConsumerWidget {
  const AdminBannersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(adminBannersProvider);

    return AdminShell(
      title: 'Publicidad',
      currentIndex: 2,
      floatingActionButton: AdminFab(
        label: 'Nuevo banner',
        icon: Icons.add_photo_alternate_rounded,
        color: const Color(0xFFEC4899),
        onPressed: () => _showBannerDialog(context, ref),
      ),
      child: bannersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (banners) {
          if (banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 64, color: MaraColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text('No hay banners publicados'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showBannerDialog(context, ref),
                    icon: const Icon(Icons.upload_rounded),
                    label: const Text('Subir publicidad'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminBannersProvider);
              ref.invalidate(heroBannersProvider);
              ref.invalidate(stripBannersProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              itemCount: banners.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AdminHeroBanner(
                    title: '${banners.length} banners activos',
                    subtitle: 'Sube imágenes promocionales para el carrusel y franjas del home.',
                  );
                }
                final banner = banners[index - 1];
                return _BannerAdminCard(
                  banner: banner,
                  onEdit: () => _showBannerDialog(context, ref, existing: banner),
                  onToggle: () async {
                    await ref.read(adminRepositoryProvider).updateBanner(
                          banner.id,
                          UpdateBannerInput(isActive: !banner.isActive),
                        );
                    ref.invalidate(adminBannersProvider);
                    ref.invalidate(heroBannersProvider);
                    ref.invalidate(stripBannersProvider);
                  },
                  onDelete: () => _confirmDelete(context, ref, banner),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AdminBanner banner,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar banner'),
        content: Text('¿Quitar "${banner.title}" del home?'),
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

    await ref.read(adminRepositoryProvider).deleteBanner(banner.id);
    ref.invalidate(adminBannersProvider);
    ref.invalidate(adminStatsProvider);
    ref.invalidate(heroBannersProvider);
    ref.invalidate(stripBannersProvider);
  }

  Future<void> _showBannerDialog(
    BuildContext context,
    WidgetRef ref, {
    AdminBanner? existing,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => _BannerFormDialog(existing: existing),
    );
    ref.invalidate(adminBannersProvider);
    ref.invalidate(adminStatsProvider);
    ref.invalidate(heroBannersProvider);
    ref.invalidate(stripBannersProvider);
  }
}

class _BannerAdminCard extends StatelessWidget {
  const _BannerAdminCard({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final AdminBanner banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: banner.isActive ? const Color(0xFFE2E8F0) : MaraColors.rose.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: MaraNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: banner.isActive
                            ? MaraColors.green.withValues(alpha: 0.12)
                            : MaraColors.rose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: banner.isActive ? MaraColors.green : MaraColors.rose,
                        ),
                      ),
                    ),
                  ],
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(banner.subtitle!, style: const TextStyle(color: MaraColors.textSecondary, fontSize: 12)),
                ],
                const SizedBox(height: 8),
                Text(
                  '${banner.placement == 'HOME_HERO' ? 'Carrusel principal' : 'Franja promocional'} · Orden ${banner.sortOrder}',
                  style: const TextStyle(fontSize: 11, color: MaraColors.textTertiary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onToggle,
                      child: Text(banner.isActive ? 'Desactivar' : 'Activar'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, color: MaraColors.rose),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerFormDialog extends ConsumerStatefulWidget {
  const _BannerFormDialog({this.existing});

  final AdminBanner? existing;

  @override
  ConsumerState<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<_BannerFormDialog> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _badgeController = TextEditingController();
  final _buttonController = TextEditingController();
  final _linkController = TextEditingController();
  final _sortController = TextEditingController(text: '0');

  String _placement = 'HOME_HERO';
  PickedImage? _pickedImage;
  String? _existingImageUrl;
  bool _submitting = false;
  bool _picking = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    if (b != null) {
      _titleController.text = b.title;
      _subtitleController.text = b.subtitle ?? '';
      _badgeController.text = b.badgeText ?? '';
      _buttonController.text = b.buttonText ?? '';
      _linkController.text = b.linkUrl ?? '';
      _sortController.text = '${b.sortOrder}';
      _placement = b.placement;
      _existingImageUrl = b.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeController.dispose();
    _buttonController.dispose();
    _linkController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await pickProductImage();
      if (file != null) setState(() => _pickedImage = file);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().length < 2) return;
    if (_pickedImage == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sube una imagen para el banner')),
      );
      return;
    }

    final linkTrimmed = _linkController.text.trim();
    if (linkTrimmed.isNotEmpty && !_isValidUrl(linkTrimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace debe ser una URL válida (ej. https://maraplus.com)'),
          backgroundColor: MaraColors.rose,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      var imageUrl = _existingImageUrl ?? '';
      final subtitleTrimmed = _subtitleController.text.trim();
      final badgeTrimmed = _badgeController.text.trim();
      final buttonTrimmed = _buttonController.text.trim();

      if (_pickedImage != null) {
        imageUrl = await repo.uploadProductImage(
          fileName: _pickedImage!.name,
          bytes: _pickedImage!.bytes,
          mimeType: _pickedImage!.mimeType,
        );
      }

      if (_isEdit) {
        await repo.updateBanner(
          widget.existing!.id,
          UpdateBannerInput(
            title: _titleController.text.trim(),
            subtitle: subtitleTrimmed,
            imageUrl: imageUrl,
            badgeText: badgeTrimmed,
            buttonText: buttonTrimmed,
            linkUrl: linkTrimmed,
            placement: _placement,
            sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
          ),
        );
      } else {
        await repo.createBanner(
          CreateBannerInput(
            title: _titleController.text.trim(),
            subtitle: subtitleTrimmed.isEmpty ? null : subtitleTrimmed,
            imageUrl: imageUrl,
            badgeText: badgeTrimmed.isEmpty ? null : badgeTrimmed,
            buttonText: buttonTrimmed.isEmpty ? null : buttonTrimmed,
            linkUrl: linkTrimmed.isEmpty ? null : linkTrimmed,
            placement: _placement,
            sortOrder: int.tryParse(_sortController.text.trim()) ?? 0,
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Editar banner' : 'Nuevo banner'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _picking ? null : _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: MaraColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _pickedImage != null
                      ? Image.memory(_pickedImage!.bytes, fit: BoxFit.cover)
                      : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? MaraNetworkImage(imageUrl: _existingImageUrl!, fit: BoxFit.cover)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.upload_file_rounded, color: MaraColors.navy.withValues(alpha: 0.4)),
                                const SizedBox(height: 6),
                                Text(
                                  _picking ? 'Cargando...' : 'Toca para subir imagen',
                                  style: const TextStyle(fontSize: 12, color: MaraColors.textSecondary),
                                ),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _subtitleController,
                decoration: const InputDecoration(labelText: 'Subtítulo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _placement,
                decoration: const InputDecoration(labelText: 'Ubicación', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'HOME_HERO', child: Text('Carrusel principal (Home)')),
                  DropdownMenuItem(value: 'HOME_STRIP', child: Text('Franja promocional')),
                ],
                onChanged: (v) => setState(() => _placement = v ?? 'HOME_HERO'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _badgeController,
                      decoration: const InputDecoration(labelText: 'Etiqueta', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _buttonController,
                      decoration: const InputDecoration(labelText: 'Texto botón', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _linkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Enlace (URL)',
                  hintText: 'Opcional — https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sortController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Orden', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: Text(_submitting ? 'Guardando...' : (_isEdit ? 'Guardar' : 'Publicar')),
        ),
      ],
    );
  }
}
