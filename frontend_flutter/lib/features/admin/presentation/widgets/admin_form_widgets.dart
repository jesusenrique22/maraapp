import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../data/image_picker.dart';

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class AdminProductImagePicker extends StatelessWidget {
  const AdminProductImagePicker({
    super.key,
    required this.pickedImage,
    required this.picking,
    required this.onPick,
    required this.onClear,
  });

  final PickedImage? pickedImage;
  final bool picking;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final bytes = pickedImage?.bytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: MaraColors.lightBlue,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: MaraColors.navy.withValues(alpha: 0.12),
              width: 1.5,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: bytes == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: MaraColors.navy.withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sube una foto del producto',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(bytes, fit: BoxFit.cover),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: Colors.black54),
                        onPressed: onClear,
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: picking ? null : onPick,
          icon: picking
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.upload_file_rounded),
          label: Text(bytes == null ? 'Seleccionar imagen' : 'Cambiar imagen'),
          style: FilledButton.styleFrom(backgroundColor: MaraColors.green),
        ),
      ],
    );
  }
}
