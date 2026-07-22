import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../domain/models/catalog_models.dart';

class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedSlug;
  final ValueChanged<String> onSelected;

  static IconData iconForSlug(String slug) {
    return switch (slug) {
      'farmacia' => Icons.healing_outlined,
      'panaderia' => Icons.bakery_dining_outlined,
      'charcuteria' => Icons.kebab_dining_outlined,
      'bodegon' => Icons.storefront_outlined,
      'alimentos-bebidas' => Icons.shopping_bag_outlined,
      'mascotas' => Icons.pets_outlined,
      _ => Icons.grid_view_outlined,
    };
  }

  static LinearGradient gradientForSlug(String slug) {
    return switch (slug) {
      'farmacia' => MaraColors.gradientGreen,
      'panaderia' => const LinearGradient(
          colors: [Color(0xFFFF8A3D), Color(0xFFE85A00)],
        ),
      'charcuteria' => const LinearGradient(
          colors: [Color(0xFFE85A00), Color(0xFF0A1628)],
        ),
      'bodegon' => const LinearGradient(
          colors: [Color(0xFF0A1628), Color(0xFFFF6A00)],
        ),
      'alimentos-bebidas' => const LinearGradient(
          colors: [Color(0xFFFF6A00), Color(0xFF1B2A4A)],
        ),
      'mascotas' => const LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
        ),
      _ => MaraColors.gradientGreen,
    };
  }

  static String subtitleForSlug(String slug) {
    return switch (slug) {
      'farmacia' => 'Salud 24 horas',
      'panaderia' => 'Fresco cada día',
      'charcuteria' => 'Embutidos y más',
      'bodegon' => 'Todo en un lugar',
      'alimentos-bebidas' => 'Despensa y bebidas',
      'mascotas' => 'No disponible',
      _ => 'Explorar productos',
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedSlug == null;
            return _CategoryCard(
              label: 'Todos',
              subtitle: 'Ver catálogo completo',
              icon: Icons.apps_rounded,
              gradient: MaraColors.gradientNavy,
              accent: MaraColors.navyMid,
              selected: selected,
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected('');
              },
            );
          }

          final category = categories[index - 1];
          final selected = selectedSlug == category.slug;

          return _CategoryCard(
            label: category.name,
            subtitle: category.description ?? subtitleForSlug(category.slug),
            icon: iconForSlug(category.slug),
            gradient: gradientForSlug(category.slug),
            accent: gradientForSlug(category.slug).colors.first,
            selected: selected,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(category.slug);
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 128,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? widget.accent
                  : const Color(0xFFE2E8F0),
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.accent.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : MaraShadows.card,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: widget.selected
                        ? widget.gradient
                        : LinearGradient(
                            colors: [
                              widget.accent.withValues(alpha: 0.12),
                              widget.accent.withValues(alpha: 0.04),
                            ],
                          ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Icon(
                          widget.icon,
                          size: 56,
                          color: (widget.selected
                                  ? Colors.white
                                  : widget.accent)
                              .withValues(alpha: 0.15),
                        ),
                      ),
                      Center(
                        child: Icon(
                          widget.icon,
                          size: 30,
                          color: widget.selected
                              ? Colors.white
                              : widget.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: widget.selected
                                ? widget.accent
                                : MaraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.25,
                            color: MaraColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
