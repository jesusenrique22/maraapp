import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Bridge al `window.__farmaPwa` definido en `web/index.html`.
class PwaInstallBridge {
  const PwaInstallBridge();

  FarmaPwaApi? get _api {
    final value = _farmaPwa;
    if (value == null) return null;
    return value;
  }

  bool get isSupported => _api != null;

  bool get isStandalone => _api?.isStandalone() ?? false;

  bool get canPrompt => _api?.canPrompt ?? false;

  bool get isIosSafariHint => _api?.isIos() ?? false;

  void Function() onChange(void Function() listener) {
    void handle(web.Event _) => listener();
    final jsHandler = handle.toJS;
    web.window.addEventListener('farma-pwa-changed', jsHandler);

    final api = _api;
    JSFunction? unsubscribe;
    if (api != null) {
      unsubscribe = api.onChange(listener.toJS);
    }

    return () {
      web.window.removeEventListener('farma-pwa-changed', jsHandler);
      unsubscribe?.callAsFunction();
    };
  }

  Future<PwaInstallOutcome> promptInstall() async {
    final api = _api;
    if (api == null || !api.canPrompt) {
      return PwaInstallOutcome.unavailable;
    }

    final result = await api.promptInstall().toDart;
    final outcome = result.dartify()?.toString();
    return switch (outcome) {
      'accepted' => PwaInstallOutcome.accepted,
      'dismissed' => PwaInstallOutcome.dismissed,
      _ => PwaInstallOutcome.unavailable,
    };
  }
}

enum PwaInstallOutcome {
  accepted,
  dismissed,
  unavailable,
}

@JS('__farmaPwa')
external FarmaPwaApi? get _farmaPwa;

/// Tipado del objeto inyectado por `index.html`.
extension type FarmaPwaApi(JSObject _) implements JSObject {
  external bool isStandalone();
  external bool get canPrompt;
  external bool isIos();
  external JSFunction onChange(JSFunction cb);
  external JSPromise<JSAny?> promptInstall();
}
