import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../../../shared/widgets/mara_logo.dart';
import '../../providers/admin_providers.dart';
import 'admin_ui_widgets.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final int currentIndex;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: AdminSoft.background,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          if (wide)
            _AdminSidebar(
              currentIndex: currentIndex,
              userName: auth.session?.user.name ?? 'Admin',
              onLogout: () async {
                await ref.read(adminAuthProvider.notifier).logout();
                if (context.mounted) context.go('/medic-plus/login');
              },
            ),
          Expanded(
            child: Column(
              children: [
                _AdminTopBar(
                  title: title,
                  wide: wide,
                  onMenu: () => _showMobileMenu(context, ref),
                  onLogout: () async {
                    await ref.read(adminAuthProvider.notifier).logout();
                    if (context.mounted) context.go('/medic-plus/login');
                  },
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : _AdminBottomNav(
              currentIndex: currentIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/admin');
                  case 1:
                    context.go('/admin/products');
                  case 2:
                    context.go('/admin/banners');
                  case 3:
                    _showMobileMenu(context, ref);
                }
              },
            ),
    );
  }

  void _showMobileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: MaraColors.textTertiary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Navegación',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MaraColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      children: [
                        _MobileMenuItem(label: 'Inicio', onTap: () { Navigator.pop(context); context.go('/admin'); }),
                        _MobileMenuItem(label: 'Estadísticas', onTap: () { Navigator.pop(context); context.go('/admin/stats'); }),
                        _MobileMenuItem(label: 'Productos', onTap: () { Navigator.pop(context); context.go('/admin/products'); }),
                        _MobileMenuItem(label: 'Nuevo producto', onTap: () { Navigator.pop(context); context.go('/admin/products/new'); }),
                        _MobileMenuItem(label: 'Publicidad', onTap: () { Navigator.pop(context); context.go('/admin/banners'); }),
                        _MobileMenuItem(label: 'Médicos', onTap: () { Navigator.pop(context); context.go('/admin/doctors'); }),
                        _MobileMenuItem(label: 'Pacientes', onTap: () { Navigator.pop(context); context.go('/admin/patients'); }),
                        _MobileMenuItem(label: 'Sucursales', onTap: () { Navigator.pop(context); context.go('/admin/branches'); }),
                        _MobileMenuItem(label: 'Ver tienda', onTap: () { Navigator.pop(context); context.go('/home'); }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.wide,
    required this.onMenu,
    required this.onLogout,
  });

  final String title;
  final bool wide;
  final VoidCallback onMenu;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 20, wide ? 40 : 16, 20),
      decoration: BoxDecoration(
        color: AdminSoft.background,
        border: Border(
          bottom: BorderSide(color: MaraColors.textPrimary.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          if (!wide)
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: MaraColors.textPrimary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
            ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: wide ? 15 : 15,
                color: MaraColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (!wide)
            IconButton(
              onPressed: onLogout,
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: MaraColors.textSecondary,
                padding: EdgeInsets.zero,
                minimumSize: const Size(36, 36),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: MaraColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.arrow_forward, size: 14, color: MaraColors.textTertiary.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: MaraColors.textPrimary.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Inicio',
                selected: currentIndex == 0,
                onTap: () => onDestinationSelected(0),
              ),
              _BottomNavItem(
                label: 'Productos',
                selected: currentIndex == 1,
                onTap: () => onDestinationSelected(1),
              ),
              _BottomNavItem(
                label: 'Publicidad',
                selected: currentIndex == 2,
                onTap: () => onDestinationSelected(2),
              ),
              _BottomNavItem(
                label: 'Más',
                selected: currentIndex == 3 ||
                    currentIndex == 4 ||
                    currentIndex == 5 ||
                    currentIndex == 6,
                onTap: () => onDestinationSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? MaraColors.textPrimary : MaraColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.currentIndex,
    required this.userName,
    required this.onLogout,
  });

  final int currentIndex;
  final String userName;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: MaraColors.textPrimary.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MaraLogo(height: 34, dark: false),
              const SizedBox(height: 6),
              Text(
                'Administración',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MaraColors.textSecondary.withValues(alpha: 0.9),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _NavItem(icon: Icons.home_outlined, label: 'Inicio', selected: currentIndex == 0, onTap: () => context.go('/admin')),
                    _NavItem(icon: Icons.insights_outlined, label: 'Estadísticas', selected: currentIndex == 6, onTap: () => context.go('/admin/stats')),
                    _NavItem(icon: Icons.inventory_2_outlined, label: 'Productos', selected: currentIndex == 1, onTap: () => context.go('/admin/products')),
                    _NavItem(icon: Icons.campaign_outlined, label: 'Publicidad', selected: currentIndex == 2, onTap: () => context.go('/admin/banners')),
                    _NavItem(icon: Icons.medical_services_outlined, label: 'Médicos', selected: currentIndex == 3, onTap: () => context.go('/admin/doctors')),
                    _NavItem(icon: Icons.people_outline, label: 'Pacientes', selected: currentIndex == 4, onTap: () => context.go('/admin/patients')),
                    _NavItem(icon: Icons.storefront_outlined, label: 'Sucursales', selected: currentIndex == 5, onTap: () => context.go('/admin/branches')),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(height: 1, color: MaraColors.textPrimary.withValues(alpha: 0.06)),
                    ),
                    _NavItem(icon: Icons.add_box_outlined, label: 'Nuevo producto', selected: false, onTap: () => context.go('/admin/products/new')),
                    _NavItem(icon: Icons.open_in_new, label: 'Ver tienda', selected: false, onTap: () => context.go('/home'), muted: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AdminSoft.tintGreen.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: MaraColors.green.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: MaraColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: MaraColors.greenDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MaraColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: onLogout,
                            child: const Text(
                              'Cerrar sesión',
                              style: TextStyle(
                                color: MaraColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          hoverColor: AdminSoft.tintGreen.withValues(alpha: 0.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? AdminSoft.tintGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: MaraColors.green.withValues(alpha: 0.15))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: muted
                      ? MaraColors.textTertiary
                      : selected
                          ? MaraColors.greenDark
                          : MaraColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: muted
                          ? MaraColors.textTertiary
                          : selected
                              ? MaraColors.greenDark
                              : MaraColors.textPrimary.withValues(alpha: 0.75),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
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
