/// Plataforma PWA: stub (móvil/desktop nativo) vs web.
library;

export 'pwa_install_bridge_stub.dart'
    if (dart.library.js_interop) 'pwa_install_bridge_web.dart';
