import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminPatientsScreen extends ConsumerWidget {
  const AdminPatientsScreen({super.key});

  Future<void> _deletePatient(
    BuildContext context,
    WidgetRef ref,
    String id,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dar de baja paciente'),
        content: Text('¿Eliminar la cuenta de $name?'),
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
      await ref.read(adminRepositoryProvider).deleteAdminPatient(id);
      ref.invalidate(adminPatientsProvider);
      ref.invalidate(adminStatsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paciente eliminado'), backgroundColor: MaraColors.green),
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
    final patientsAsync = ref.watch(adminPatientsProvider);

    return AdminShell(
      title: 'Pacientes',
      currentIndex: 4,
      child: patientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (patients) {
          if (patients.isEmpty) {
            return const AdminEmptyState(
              icon: Icons.people_outline_rounded,
              title: 'Sin pacientes registrados',
              subtitle: 'Cuando los usuarios se registren aparecerán aquí.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminPatientsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              itemCount: patients.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return AdminHeroBanner(
                    title: '${patients.length} pacientes registrados',
                    subtitle: 'Administra cuentas de clientes y usuarios de Medic Plus.',
                  );
                }

                final pat = patients[index - 1];
                final isActive = pat['isActive'] as bool? ?? true;
                final name = pat['name'] as String? ?? 'Paciente';

                return AdminEntityCard(
                  avatar: CircleAvatar(
                    backgroundColor: MaraColors.green.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: const TextStyle(color: MaraColors.green, fontWeight: FontWeight.w900),
                    ),
                  ),
                  title: name,
                  subtitle: pat['email'] as String? ?? '',
                  badge: AdminStatusBadge(active: isActive),
                  trailing: IconButton(
                    onPressed: () => _deletePatient(context, ref, pat['id'] as String, name),
                    icon: const Icon(Icons.delete_outline_rounded, color: MaraColors.rose),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
