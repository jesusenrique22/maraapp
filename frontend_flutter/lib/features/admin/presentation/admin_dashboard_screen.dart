import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/mara_theme.dart';
import '../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final branchesAsync = ref.watch(adminBranchesProvider);
    final user = ref.watch(adminAuthProvider).session?.user;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 900 ? 40.0 : 20.0;

    return AdminShell(
      title: 'Inicio',
      currentIndex: 0,
      child: RefreshIndicator(
        color: MaraColors.green,
        strokeWidth: 2,
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
          ref.invalidate(adminProductsProvider);
          ref.invalidate(adminBannersProvider);
          ref.invalidate(adminDoctorsProvider);
          ref.invalidate(adminPatientsProvider);
          ref.invalidate(adminBranchesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 32, horizontalPadding, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: statsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(80),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (stats) {
                  final branchCount = branchesAsync.maybeWhen(
                    data: (branches) => branches.length,
                    orElse: () => null,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AdminPageIntro(
                        userName: user?.name ?? 'Administrador',
                        apiOnline: stats.apiOnline,
                      ),
                      const SizedBox(height: 32),
                      AdminMetricBand(
                        metrics: [
                          AdminMetric(label: 'Productos', value: stats.products),
                          AdminMetric(label: 'Banners', value: stats.banners),
                          AdminMetric(label: 'Médicos', value: stats.doctors),
                          AdminMetric(label: 'Pacientes', value: stats.patients),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 16,
                            decoration: BoxDecoration(
                              color: MaraColors.green.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Secciones',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: MaraColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AdminDirectoryPanel(
                        items: _directoryItems(context, stats, branchCount),
                      ),
                      const SizedBox(height: 28),
                      AdminInlineActions(
                        onAddProduct: () => context.go('/admin/products/new'),
                        onViewStore: () => context.go('/home'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<AdminDirectoryItem> _directoryItems(
  BuildContext context,
  AdminStats stats,
  int? branchCount,
) {
  return [
    AdminDirectoryItem(
      title: 'Estadísticas',
      subtitle: 'Ventas, flujo y recomendaciones',
      count: 'Live',
      icon: Icons.insights_outlined,
      onTap: () => context.go('/admin/stats'),
    ),
    AdminDirectoryItem(
      title: 'Productos',
      subtitle: 'Catálogo, precios e inventario',
      count: _formatCount(stats.products),
      icon: Icons.inventory_2_outlined,
      onTap: () => context.go('/admin/products'),
    ),
    AdminDirectoryItem(
      title: 'Publicidad',
      subtitle: 'Banners y promociones del home',
      count: _formatCount(stats.banners),
      icon: Icons.campaign_outlined,
      onTap: () => context.go('/admin/banners'),
    ),
    AdminDirectoryItem(
      title: 'Médicos',
      subtitle: 'Equipo y especialidades',
      count: _formatCount(stats.doctors),
      icon: Icons.medical_services_outlined,
      onTap: () => context.go('/admin/doctors'),
    ),
    AdminDirectoryItem(
      title: 'Pacientes',
      subtitle: 'Usuarios de Medic Plus',
      count: _formatCount(stats.patients),
      icon: Icons.people_outline,
      onTap: () => context.go('/admin/patients'),
    ),
    AdminDirectoryItem(
      title: 'Sucursales',
      subtitle: 'Locales y puntos de retiro',
      count: branchCount != null ? _formatCount(branchCount) : '—',
      icon: Icons.storefront_outlined,
      onTap: () => context.go('/admin/branches'),
    ),
  ];
}

String _formatCount(int n) => n.toString();
