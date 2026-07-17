import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_repository.dart';
import '../data/auth_storage.dart';
import '../../home/domain/models/catalog_models.dart';
import '../../branches/domain/branch_models.dart';
import '../../branches/providers/branches_provider.dart';
import '../domain/admin_models.dart';

class AdminAuthState {
  const AdminAuthState({
    this.session,
    this.isLoading = false,
    this.isRestoring = false,
    this.error,
  });

  final AdminSession? session;
  final bool isLoading;
  final bool isRestoring;
  final String? error;

  bool get isAuthenticated => session != null;
  bool get isReady => !isRestoring && !isLoading;
}

class AdminAuthNotifier extends StateNotifier<AdminAuthState> {
  AdminAuthNotifier(this._repository, this._storage, this._api)
      : super(const AdminAuthState()) {
    _restore();
  }

  final AdminRepository _repository;
  final AuthStorage _storage;
  final ApiClient _api;

  /// Invalidates in-flight restore/login races.
  int _authGeneration = 0;

  int _nextGeneration() => ++_authGeneration;

  Future<void> _persistSession(AdminSession session) async {
    await _storage.saveSession(
      token: session.token,
      email: session.user.email,
      name: session.user.name,
      userId: session.user.id,
      role: session.user.role,
      avatarUrl: session.user.avatarUrl,
    );
  }

  Future<void> _clearSession({AdminAuthState? nextState}) async {
    await _storage.clear();
    _api.setAuthToken(null);
    state = nextState ?? const AdminAuthState();
  }

  Future<void> _restore() async {
    final generation = _nextGeneration();
    state = const AdminAuthState(isRestoring: true);

    try {
      final stored = await _storage.readSession();
      if (generation != _authGeneration) return;

      if (stored == null || stored.token.isEmpty) {
        state = const AdminAuthState();
        return;
      }

      _api.setAuthToken(stored.token);
      final user = await _repository.me();
      if (generation != _authGeneration) return;

      final session = AdminSession(token: stored.token, user: user);
      await _persistSession(session);
      if (generation != _authGeneration) return;

      state = AdminAuthState(session: session);
    } on ApiException catch (error) {
      if (generation != _authGeneration) return;

      _api.setAuthToken(null);
      if (error.statusCode == 401) {
        await _storage.clear();
        state = const AdminAuthState();
        return;
      }

      state = const AdminAuthState(
        error: 'No se pudo validar tu sesión. Inicia sesión de nuevo.',
      );
    } catch (_) {
      if (generation != _authGeneration) return;

      _api.setAuthToken(null);
      state = const AdminAuthState(
        error: 'Sin conexión al servidor. Inicia sesión cuando vuelva la red.',
      );
    }
  }

  Future<bool> login(String email, String password) async {
    final generation = _nextGeneration();
    state = const AdminAuthState(isLoading: true);

    try {
      final session = await _repository.login(email, password);
      if (generation != _authGeneration) return false;

      _api.setAuthToken(session.token);
      await _persistSession(session);
      if (generation != _authGeneration) return false;

      state = AdminAuthState(session: session);
      return true;
    } on ApiException catch (error) {
      if (generation != _authGeneration) return false;

      await _clearSession(
        nextState: AdminAuthState(error: error.message),
      );
      return false;
    } catch (_) {
      if (generation != _authGeneration) return false;

      await _clearSession(
        nextState: const AdminAuthState(
          error:
              'No se pudo conectar con el servidor. Verifica que la API esté activa.',
        ),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    final generation = _nextGeneration();
    state = const AdminAuthState(isLoading: true);

    try {
      final session = await _repository.register(email, password, name);
      if (generation != _authGeneration) return false;

      _api.setAuthToken(session.token);
      await _persistSession(session);
      if (generation != _authGeneration) return false;

      state = AdminAuthState(session: session);
      return true;
    } on ApiException catch (error) {
      if (generation != _authGeneration) return false;

      await _clearSession(
        nextState: AdminAuthState(error: error.message),
      );
      return false;
    } catch (_) {
      if (generation != _authGeneration) return false;

      await _clearSession(
        nextState: const AdminAuthState(
          error:
              'No se pudo conectar con el servidor. Verifica que la API esté activa.',
        ),
      );
      return false;
    }
  }

  Future<void> logout() async {
    _nextGeneration();
    await _clearSession();
  }

  Future<bool> updateAvatar(String avatarUrl) async {
    if (state.session == null) return false;
    try {
      final response = await _api.postMap('/auth/avatar', {'avatarUrl': avatarUrl});
      final updatedUser = AdminUser.fromJson(response);
      final updatedSession = AdminSession(token: state.session!.token, user: updatedUser);
      await _persistSession(updatedSession);
      state = AdminAuthState(session: updatedSession);
      return true;
    } catch (_) {
      return false;
    }
  }
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  ref.keepAlive();
  return AuthStorage();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  ref.keepAlive();
  return AdminRepository(ref.watch(apiClientProvider));
});

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, AdminAuthState>((ref) {
  ref.keepAlive();
  return AdminAuthNotifier(
    ref.watch(adminRepositoryProvider),
    ref.watch(authStorageProvider),
    ref.watch(apiClientProvider),
  );
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchStats();
});

final adminSalesPeriodProvider = StateProvider<int>((ref) => 30);

final adminSalesDashboardProvider =
    FutureProvider<AdminSalesDashboard>((ref) async {
  ref.watch(adminAuthProvider);
  final days = ref.watch(adminSalesPeriodProvider);
  return ref.watch(adminRepositoryProvider).fetchSalesDashboard(days: days);
});

final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchProducts();
});

final adminCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchCategories();
});

final adminBannersProvider = FutureProvider<List<AdminBanner>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchBanners();
});

final adminDoctorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchAdminDoctors();
});

final adminPatientsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(adminRepositoryProvider).fetchAdminPatients();
});

final adminBranchesProvider = FutureProvider<List<Branch>>((ref) async {
  ref.watch(adminAuthProvider);
  return ref.watch(branchesRepositoryProvider).fetchAdminBranches();
});
