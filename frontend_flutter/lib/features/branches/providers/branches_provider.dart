import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../data/branches_repository.dart';
import '../domain/branch_models.dart';

final branchesRepositoryProvider = Provider<BranchesRepository>((ref) {
  return BranchesRepository(ref.watch(apiClientProvider));
});

final branchesProvider = FutureProvider<List<Branch>>((ref) {
  return ref.watch(branchesRepositoryProvider).fetchBranches();
});

class SelectedBranchNotifier extends StateNotifier<Branch?> {
  SelectedBranchNotifier() : super(null) {
    _restore();
  }

  static const _key = 'maraplus_selected_branch';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      // Stored as branch id only; full object resolved when branches load
      _storedId = raw;
    } catch (_) {}
  }

  String? _storedId;

  Future<void> select(Branch branch) async {
    state = branch;
    _storedId = branch.id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, branch.id);
  }

  void resolveFromList(List<Branch> branches) {
    if (state != null) return;
    if (_storedId != null) {
      final match = branches.where((b) => b.id == _storedId);
      if (match.isNotEmpty) {
        state = match.first;
        return;
      }
    }
    final main = branches.where((b) => b.isMain);
    if (main.isNotEmpty) {
      state = main.first;
    } else if (branches.isNotEmpty) {
      state = branches.first;
    }
  }
}

final selectedBranchProvider =
    StateNotifierProvider<SelectedBranchNotifier, Branch?>((ref) {
  final notifier = SelectedBranchNotifier();
  ref.listen(branchesProvider, (_, next) {
    next.whenData(notifier.resolveFromList);
  });
  return notifier;
});
