import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'MaraPlus';

  /// Override en build: --dart-define=API_BASE_URL=https://tu-dominio.com
  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }

    if (kIsWeb) {
      // Producción web: misma URL que la página (nginx sirve API + Flutter).
      if (!kDebugMode) {
        return Uri.base.origin;
      }
      return 'http://127.0.0.1:3000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://127.0.0.1:3000';
  }
}
