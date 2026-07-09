import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_branches_screen.dart';
import '../../features/admin/presentation/admin_add_product_screen.dart';
import '../../features/admin/presentation/admin_banners_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_doctors_screen.dart';
import '../../features/admin/presentation/admin_edit_product_screen.dart';
import '../../features/admin/presentation/admin_patients_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/providers/admin_providers.dart';
import '../../features/doctor/presentation/doctor_dashboard_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/patient/presentation/patient_telemedicine_screen.dart';
import '../../features/welcome/presentation/medic_plus_login_screen.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import 'auth_redirect.dart';

class RouterRefreshNotifier extends ChangeNotifier {
  void notifyRouter() => notifyListeners();
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  ref.keepAlive();
  final notifier = RouterRefreshNotifier();
  ref.listen(adminAuthProvider, (_, __) => notifier.notifyRouter());
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  ref.keepAlive();
  final refresh = ref.watch(routerRefreshProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final authState = ref.read(adminAuthProvider);
      final path = state.matchedLocation;

      if (authState.isRestoring) return null;

      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.session?.user.role;

      if (isAuthenticated) {
        if (userRole == 'ADMIN' && !path.startsWith('/admin')) {
          return '/admin';
        }
        if (userRole == 'DOCTOR' && !path.startsWith('/doctor')) {
          return '/doctor';
        }
      }

      final isDoctorRoute = path.startsWith('/doctor');
      if (isDoctorRoute) {
        if (!isAuthenticated) {
          return AuthRedirect.staffLoginPath(redirect: path);
        }
        if (userRole != 'DOCTOR') return '/doctor';
      }

      final isAdminRoute = path.startsWith('/admin');
      if (isAdminRoute) {
        if (!isAuthenticated) {
          return AuthRedirect.staffLoginPath(redirect: path);
        }
        if (userRole != 'ADMIN') return '/admin';
      }

      final isLoginRoute = path.startsWith('/login/') ||
          path == '/medic-plus/login' ||
          path == '/admin/login';

      final isMedicPlusApp = path == '/medic-plus';
      if (isMedicPlusApp && !isAuthenticated) {
        return AuthRedirect.medicPlusLoginPath(redirect: state.uri.toString());
      }

      if (path == '/welcome' && isAuthenticated) {
        return AuthRedirect.defaultHomeForRole(userRole);
      }

      if (isLoginRoute && isAuthenticated) {
        if (userRole == 'ADMIN' || userRole == 'DOCTOR') {
          return AuthRedirect.defaultHomeForRole(userRole);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final params = state.uri.queryParameters;
          final initialTab = switch (params['tab']) {
            'cart' => 2,
            'account' => 3,
            _ => params['cart'] == '1' ? 2 : 0,
          };
          final resumeCheckout = params['checkout'] == '1';
          return HomeScreen(
            initialTab: initialTab,
            resumeCheckout: resumeCheckout,
          );
        },
      ),
      GoRoute(
        path: '/login/store',
        builder: (context, state) => MaraLoginScreen(
          loginContext: MaraLoginContext.store,
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/login/medic-plus',
        builder: (context, state) => MaraLoginScreen(
          loginContext: MaraLoginContext.medicPlus,
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/login/staff',
        builder: (context, state) => MaraLoginScreen(
          loginContext: MaraLoginContext.staff,
          redirect: state.uri.queryParameters['redirect'],
        ),
      ),
      GoRoute(
        path: '/admin/login',
        redirect: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return AuthRedirect.staffLoginPath(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/medic-plus/login',
        redirect: (context, state) {
          final redirect = state.uri.queryParameters['redirect'];
          return AuthRedirect.medicPlusLoginPath(redirect: redirect);
        },
      ),
      GoRoute(
        path: '/medic-plus',
        builder: (context, state) => const PatientTelemedicineScreen(),
      ),
      GoRoute(
        path: '/doctor',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: '/admin/products/new',
        builder: (context, state) => const AdminAddProductScreen(),
      ),
      GoRoute(
        path: '/admin/products/:id/edit',
        builder: (context, state) => AdminEditProductScreen(
          productId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/banners',
        builder: (context, state) => const AdminBannersScreen(),
      ),
      GoRoute(
        path: '/admin/doctors',
        builder: (context, state) => const AdminDoctorsScreen(),
      ),
      GoRoute(
        path: '/admin/patients',
        builder: (context, state) => const AdminPatientsScreen(),
      ),
      GoRoute(
        path: '/admin/branches',
        builder: (context, state) => const AdminBranchesScreen(),
      ),
    ],
  );
});
