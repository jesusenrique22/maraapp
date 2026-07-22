/// Contexto de login: tienda (inventario) vs Salud360 (telemedicina).
enum MaraLoginContext {
  store,
  medicPlus,
  staff,
}

/// Rutas seguras después de login y helpers para volver al flujo anterior.
class AuthRedirect {
  AuthRedirect._();

  static const checkoutReturnPath = '/home?cart=1&checkout=1';

  static MaraLoginContext parseContext(String? raw) {
    return switch (raw) {
      'medic-plus' => MaraLoginContext.medicPlus,
      'staff' => MaraLoginContext.staff,
      _ => MaraLoginContext.store,
    };
  }

  static String contextParam(MaraLoginContext context) {
    return switch (context) {
      MaraLoginContext.medicPlus => 'medic-plus',
      MaraLoginContext.staff => 'staff',
      MaraLoginContext.store => 'store',
    };
  }

  static String storeLoginPath({String? redirect}) {
    return _loginPath(MaraLoginContext.store, redirect: redirect);
  }

  static String medicPlusLoginPath({String? redirect}) {
    return _loginPath(MaraLoginContext.medicPlus, redirect: redirect);
  }

  static String staffLoginPath({String? redirect}) {
    return _loginPath(MaraLoginContext.staff, redirect: redirect);
  }

  /// Compatibilidad con rutas antiguas.
  static String loginPath({String? redirect, MaraLoginContext? context}) {
    return _loginPath(context ?? MaraLoginContext.medicPlus, redirect: redirect);
  }

  static String _loginPath(MaraLoginContext context, {String? redirect}) {
    final base = switch (context) {
      MaraLoginContext.store => '/login/store',
      MaraLoginContext.medicPlus => '/login/medic-plus',
      MaraLoginContext.staff => '/login/staff',
    };

    final params = <String, String>{};
    if (redirect != null && redirect.isNotEmpty) {
      params['redirect'] = redirect;
    }

    if (params.isEmpty) return base;
    return '$base?${Uri(queryParameters: params).query}';
  }

  static String? sanitizeRedirect(String? redirect) {
    if (redirect == null || redirect.isEmpty) return null;

    Uri uri;
    try {
      uri = Uri.parse(redirect);
    } catch (_) {
      return null;
    }

    if (uri.hasScheme || uri.hasAuthority) return null;

    final path = uri.path;
    if (path == '/home' || path.startsWith('/home/')) return redirect;
    if (path == '/medic-plus' || path.startsWith('/medic-plus/')) {
      return redirect;
    }
    if (path.startsWith('/admin')) return redirect;
    if (path.startsWith('/doctor')) return redirect;

    return null;
  }

  static String defaultHomeForRole(String? role) {
    return switch (role) {
      'ADMIN' => '/admin',
      'DOCTOR' => '/doctor',
      _ => '/home',
    };
  }

  static String defaultAfterLogin({
    required String? role,
    required MaraLoginContext context,
    String? redirect,
  }) {
    if (role == 'ADMIN') return '/admin';
    if (role == 'DOCTOR') return '/doctor';

    final safeRedirect = sanitizeRedirect(redirect);
    if (safeRedirect != null) return safeRedirect;

    return switch (context) {
      MaraLoginContext.store => '/home?tab=account',
      MaraLoginContext.medicPlus => '/medic-plus',
      MaraLoginContext.staff => '/medic-plus',
    };
  }

  static String resolvePostLoginRoute({
    required String? role,
    String? redirect,
    MaraLoginContext context = MaraLoginContext.medicPlus,
  }) {
    return defaultAfterLogin(role: role, context: context, redirect: redirect);
  }
}
