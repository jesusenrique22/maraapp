import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';
import '../../providers/cart_provider.dart';
import '../widgets/home_header.dart';

class PrescriptionScanSheet extends ConsumerStatefulWidget {
  const PrescriptionScanSheet({
    super.key,
    this.initialBytes,
    this.initialFileName,
    this.initialMimeType,
  });

  final Uint8List? initialBytes;
  final String? initialFileName;
  final String? initialMimeType;

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PrescriptionScanSheet(),
    );
  }

  static Future<void> showWithImage(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => PrescriptionScanSheet(
        initialBytes: bytes,
        initialFileName: fileName,
        initialMimeType: mimeType,
      ),
    );
  }

  /// Abre la cámara fuera del modal (evita bloqueos en web y móvil).
  static Future<void> openCamera(BuildContext context) async {
    final navigator = Navigator.of(context);
    final hostContext = navigator.context;
    final messenger = ScaffoldMessenger.of(hostContext);

    navigator.pop();

    await Future<void>.delayed(const Duration(milliseconds: 280));

    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2000,
        preferredCameraDevice:
            kIsWeb ? CameraDevice.front : CameraDevice.rear,
      );

      if (!hostContext.mounted) return;

      if (photo == null) {
        await show(hostContext);
        return;
      }

      final bytes = await photo.readAsBytes();
      if (!hostContext.mounted) return;

      await showWithImage(
        hostContext,
        bytes: bytes,
        fileName: photo.name.isNotEmpty
            ? photo.name
            : 'receta_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: photo.mimeType ?? 'image/jpeg',
      );
    } on PlatformException catch (e) {
      if (!hostContext.mounted) return;
      final hint = kIsWeb
          ? 'Permite el acceso a la cámara en el navegador o usa Galería.'
          : (e.message ?? 'Permiso de cámara denegado');
      messenger.showSnackBar(SnackBar(content: Text(hint)));
      await show(hostContext);
    } catch (_) {
      if (!hostContext.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No se pudo usar la cámara. Intenta con Galería.'),
        ),
      );
      await show(hostContext);
    }
  }

  @override
  ConsumerState<PrescriptionScanSheet> createState() => _PrescriptionScanSheetState();
}

class _PrescriptionScanSheetState extends ConsumerState<PrescriptionScanSheet> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;
  Uint8List? _previewBytes;
  bool _autoScanStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStartAutoScan();
  }

  void _maybeStartAutoScan() {
    if (_autoScanStarted || widget.initialBytes == null) return;
    _autoScanStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scanFromBytes(
        widget.initialBytes!,
        widget.initialFileName ?? 'receta.jpg',
        widget.initialMimeType ?? 'image/jpeg',
      );
    });
  }

  Future<void> _scanFromBytes(Uint8List bytes, String name, String mime) async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _previewBytes = bytes;
    });

    try {
      final api = ref.read(apiClientProvider);
      final data = await api.scanPrescription(
        fileName: name,
        bytes: bytes,
        mimeType: mime,
      );
      if (!mounted) return;
      setState(() {
        _result = data;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Error inesperado al escanear la receta';
        _loading = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo leer la imagen seleccionada');
      return;
    }
    await _scanFromBytes(bytes, file.name, _mimeFromName(file.name));
  }

  Future<void> _pickCamera() async {
    await PrescriptionScanSheet.openCamera(context);
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _matchLabel(String status) {
    return switch (status) {
      'exact' => 'Coincidencia en inventario',
      'similar' => 'Alternativa similar',
      _ => 'No encontrado',
    };
  }

  Color _matchColor(String status) {
    return switch (status) {
      'exact' => MaraColors.green,
      'similar' => const Color(0xFFF59E0B),
      _ => MaraColors.rose,
    };
  }

  Product _toProduct(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      finalPrice: (json['finalPrice'] as num).toDouble(),
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      inStock: json['inStock'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      category: const ProductCategory(id: 'farmacia', name: 'Farmacia', slug: 'farmacia'),
      description: json['description'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _result?['items'] as List<dynamic>? ?? [];
    final summary = _result?['summary'] as Map<String, dynamic>?;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: MaraColors.green, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escáner de Receta (IA)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Lee tu receta y busca en inventario Farma Express',
                          style: TextStyle(fontSize: 12, color: MaraColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (_previewBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_previewBytes!, height: 120, width: double.infinity, fit: BoxFit.cover),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: MaraColors.green),
                const SizedBox(height: 12),
                const Text('Analizando receta e inventario...'),
              ] else if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: MaraColors.rose), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                _ScanSourceButtons(
                  onGallery: _pickGallery,
                  onCamera: _pickCamera,
                ),
              ] else if (_result == null) ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.document_scanner_rounded, size: 56, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      const Text(
                        'Sube o toma una foto de tu receta médica',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (kIsWeb) ...[
                        const SizedBox(height: 8),
                        Text(
                          'En el navegador, permite acceso a la cámara cuando te lo pida.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: MaraColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _ScanSourceButtons(
                  onGallery: _pickGallery,
                  onCamera: _pickCamera,
                ),
              ] else ...[
                if (summary != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${summary['foundExact']} exactos · ${summary['foundSimilar']} similares · ${summary['notFound']} no encontrados',
                    style: const TextStyle(fontSize: 12, color: MaraColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index] as Map<String, dynamic>;
                      final extracted = item['extracted'] as Map<String, dynamic>;
                      final status = item['matchStatus'] as String? ?? 'not_found';
                      final products = item['products'] as List<dynamic>? ?? [];
                      final medName = extracted['medicationName'] as String? ?? 'Medicamento';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(medName, style: const TextStyle(fontWeight: FontWeight.w800)),
                              if (extracted['dosage'] != null)
                                Text('Dosis: ${extracted['dosage']}', style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _matchColor(status).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _matchLabel(status),
                                  style: TextStyle(
                                    color: _matchColor(status),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              ...products.map((pJson) {
                                final p = pJson as Map<String, dynamic>;
                                final product = _toProduct(p);
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: ProductImage(
                                      imageUrl: product.imageUrl,
                                      borderRadius: BorderRadius.circular(8),
                                      categorySlug: 'farmacia',
                                    ),
                                  ),
                                  title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    product.inStock
                                        ? '\$${product.finalPrice.toStringAsFixed(2)} · En stock'
                                        : 'Sin stock',
                                  ),
                                  trailing: product.inStock
                                      ? IconButton(
                                          icon: const Icon(Icons.add_shopping_cart_rounded),
                                          color: MaraColors.green,
                                          onPressed: () {
                                            ref.read(cartProvider.notifier).addProduct(product);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('${product.name} agregado')),
                                            );
                                          },
                                        )
                                      : null,
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanSourceButtons extends StatelessWidget {
  const _ScanSourceButtons({
    required this.onGallery,
    required this.onCamera,
  });

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: _height,
            child: OutlinedButton.icon(
              onPressed: onGallery,
              icon: const Icon(Icons.photo_library_outlined, size: 20),
              label: const Text('Galería', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: _height,
            child: ElevatedButton.icon(
              onPressed: onCamera,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text('Tomar foto', maxLines: 1, overflow: TextOverflow.ellipsis),
              style: ElevatedButton.styleFrom(
                backgroundColor: MaraColors.green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size.fromHeight(_height),
                shape: shape,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
