import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../../branches/domain/branch_models.dart';
import '../../../branches/providers/branches_provider.dart';
import 'home_header.dart';

class BranchesSection extends ConsumerWidget {
  const BranchesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);

    return branchesAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(color: MaraColors.navyMid),
            ),
          ),
        ),
      ),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (branches) {
        if (branches.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'Nuestras sucursales',
                subtitle: 'El stock varía según la sucursal que elijas',
                accentColor: MaraColors.green,
              ),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    final selected = ref.watch(selectedBranchProvider)?.id == branch.id;
                    return _BranchCard(
                      branch: branch,
                      selected: selected,
                      onTap: () => ref.read(selectedBranchProvider.notifier).select(branch),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  final Branch branch;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? MaraColors.green : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? MaraShadows.elevated : MaraShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MaraColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: MaraColors.navyMid,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    branch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                ),
                if (branch.isMain)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: MaraColors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Principal',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: MaraColors.green,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              branch.fullAddress,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: MaraColors.textSecondary,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                if (branch.openingHours != null)
                  Expanded(
                    child: Text(
                      branch.openingHours!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: MaraColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (branch.phone != null)
                  Text(
                    branch.phone!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: MaraColors.navyMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: MaraColors.green, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
