import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mara_theme.dart';
import '../../branches/domain/branch_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';

class AdminBranchesScreen extends ConsumerWidget {
  const AdminBranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(adminBranchesProvider);

    return AdminShell(
      title: 'Sucursales',
      currentIndex: 5,
      child: branchesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: MaraColors.navyMid),
        ),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (branches) {
          final active = branches.where((b) => b.isActive).toList();
          if (active.isEmpty) {
            return const Center(child: Text('No hay sucursales activas'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: active.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final branch = active[index];
              return _BranchAdminCard(branch: branch);
            },
          );
        },
      ),
    );
  }
}

class _BranchAdminCard extends StatelessWidget {
  const _BranchAdminCard({required this.branch});

  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MaraShadows.card,
        border: branch.isActive
            ? null
            : Border.all(color: MaraColors.rose.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  branch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: MaraColors.navy,
                  ),
                ),
              ),
              if (branch.isMain)
                _Chip(label: 'Principal', color: MaraColors.green),
              if (!branch.isActive)
                const _Chip(label: 'Inactiva', color: MaraColors.rose),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            branch.fullAddress,
            style: const TextStyle(color: MaraColors.textSecondary, height: 1.4),
          ),
          if (branch.phone != null) ...[
            const SizedBox(height: 6),
            Text(
              branch.phone!,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: MaraColors.navyMid,
              ),
            ),
          ],
          if (branch.openingHours != null) ...[
            const SizedBox(height: 6),
            Text(
              branch.openingHours!,
              style: const TextStyle(fontSize: 12, color: MaraColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
