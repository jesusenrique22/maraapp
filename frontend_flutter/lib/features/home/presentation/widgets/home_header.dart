import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../../../shared/widgets/mara_logo.dart';

// ─────────────────────────────────────────────
//  HOME HEADER
// ─────────────────────────────────────────────
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.searchController,
    required this.search,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.onAdminTap,
    this.onCartTap,
    this.onScanTap,
    this.onNotificationsTap,
    this.cartCount = 0,
    this.notificationsCount = 0,
  });

  final TextEditingController searchController;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback? onAdminTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onScanTap;
  final VoidCallback? onNotificationsTap;
  final int cartCount;
  final int notificationsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Logo row ───
            Row(
              children: [
                // Brand
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: MaraLogo(height: 38),
                  ),
                ),
                // Action icons
                if (onAdminTap != null) ...[
                  _HeaderIcon(
                    icon: Icons.admin_panel_settings_outlined,
                    onTap: onAdminTap,
                  ),
                  const SizedBox(width: 8),
                ],
                _HeaderIcon(
                  icon: Icons.notifications_none_rounded,
                  onTap: onNotificationsTap,
                  badge: notificationsCount > 0 ? '$notificationsCount' : null,
                  iconColor: MaraColors.green,
                  badgeColor: MaraColors.green,
                ),
                const SizedBox(width: 8),
                _HeaderIcon(
                  icon: Icons.shopping_cart_outlined,
                  onTap: onCartTap,
                  badge: cartCount > 0 ? (cartCount > 99 ? '99+' : '$cartCount') : null,
                  iconColor: MaraColors.green,
                  badgeColor: MaraColors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // ─── Search ───
            Container(
              decoration: BoxDecoration(
                color: MaraColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: TextStyle(
                  color: MaraColors.textPrimary,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '¿Qué estás buscando?',
                  hintStyle: TextStyle(
                    color: MaraColors.textTertiary,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: MaraColors.green,
                    size: 22,
                  ),
                  suffixIcon: search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: MaraColors.textSecondary,
                          onPressed: onClearSearch,
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.document_scanner_rounded,
                            color: MaraColors.green,
                            size: 22,
                          ),
                          onPressed: onScanTap,
                          tooltip: 'Escanear récipe con IA',
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: MaraColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    this.badge,
    this.onTap,
    this.badgeColor,
    this.iconColor,
  });

  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: MaraColors.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(icon, color: iconColor ?? MaraColors.navy, size: 21),
          ),
          if (badge != null)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 17,
                height: 17,
                decoration: BoxDecoration(
                  color: badgeColor ?? MaraColors.rose,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION TITLE
// ─────────────────────────────────────────────
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: MaraColors.textPrimary,
                      ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: MaraColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  PRODUCT IMAGE
// ─────────────────────────────────────────────
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.borderRadius,
    this.categorySlug,
  });

  final String? imageUrl;
  final BorderRadius borderRadius;
  final String? categorySlug;

  @override
  Widget build(BuildContext context) {
    final isGeneric = imageUrl == null || 
                      imageUrl!.isEmpty || 
                      imageUrl!.contains('unsplash.com');

    if (!isGeneric) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(10.0), // Padding para que no toque los bordes y no se estire
          child: Image.network(
            imageUrl!,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain, // Mantener proporciones nítidas sin pixelar
            headers: const {'Accept': 'image/*'},
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(MaraColors.navyAccent),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        ),
      );
    }
    return ClipRRect(borderRadius: borderRadius, child: _fallback());
  }

  Widget _fallback() {
    final color = switch (categorySlug) {
      'farmacia' => const Color(0xFFDBEAFE),
      'panaderia' => const Color(0xFFFEF3C7),
      'mascotas' => const Color(0xFFEDE9FE),
      _ => MaraColors.lightBlue,
    };

    final icon = switch (categorySlug) {
      'farmacia' => Icons.medication_liquid_outlined,
      'panaderia' => Icons.bakery_dining_outlined,
      'mascotas' => Icons.pets_outlined,
      _ => Icons.inventory_2_outlined,
    };

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: color,
      child: Icon(icon, size: 48, color: MaraColors.navy.withValues(alpha: 0.35)),
    );
  }
}
