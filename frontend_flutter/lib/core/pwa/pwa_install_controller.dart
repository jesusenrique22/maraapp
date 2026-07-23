import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pwa_install_bridge.dart';

const _dismissedAtKey = 'farmaexpress_pwa_dismissed_at';
const _snoozeDuration = Duration(days: 14);

/// Estado de instalación PWA expuesto a la UI.
@immutable
class PwaInstallState {
  const PwaInstallState({
    required this.isWeb,
    required this.isStandalone,
    required this.canPrompt,
    required this.isIos,
    required this.snoozed,
    required this.ready,
  });

  final bool isWeb;
  final bool isStandalone;
  final bool canPrompt;
  final bool isIos;
  final bool snoozed;
  final bool ready;

  /// Android/Chrome: se puede disparar el prompt nativo.
  bool get shouldShowAndroidInstall =>
      isWeb && ready && !isStandalone && !snoozed && canPrompt;

  /// iOS/Safari: no hay beforeinstallprompt; se muestra guía Share → Inicio.
  bool get shouldShowIosGuide =>
      isWeb && ready && !isStandalone && !snoozed && isIos && !canPrompt;

  bool get shouldShowBanner => shouldShowAndroidInstall || shouldShowIosGuide;

  PwaInstallState copyWith({
    bool? isStandalone,
    bool? canPrompt,
    bool? isIos,
    bool? snoozed,
    bool? ready,
  }) {
    return PwaInstallState(
      isWeb: isWeb,
      isStandalone: isStandalone ?? this.isStandalone,
      canPrompt: canPrompt ?? this.canPrompt,
      isIos: isIos ?? this.isIos,
      snoozed: snoozed ?? this.snoozed,
      ready: ready ?? this.ready,
    );
  }
}

class PwaInstallController extends StateNotifier<PwaInstallState> {
  PwaInstallController(this._bridge)
      : super(
          PwaInstallState(
            isWeb: kIsWeb,
            isStandalone: false,
            canPrompt: false,
            isIos: false,
            snoozed: false,
            ready: false,
          ),
        ) {
    if (kIsWeb) {
      _init();
    }
  }

  final PwaInstallBridge _bridge;
  void Function()? _unsubscribe;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final snoozed = _isSnoozed(prefs);

    _unsubscribe = _bridge.onChange(_refreshFromBridge);
    state = state.copyWith(
      isStandalone: _bridge.isStandalone,
      canPrompt: _bridge.canPrompt,
      isIos: _bridge.isIosSafariHint,
      snoozed: snoozed,
      ready: true,
    );
  }

  void _refreshFromBridge() {
    state = state.copyWith(
      isStandalone: _bridge.isStandalone,
      canPrompt: _bridge.canPrompt,
      isIos: _bridge.isIosSafariHint,
    );
  }

  bool _isSnoozed(SharedPreferences prefs) {
    final raw = prefs.getInt(_dismissedAtKey);
    if (raw == null) return false;
    final dismissedAt = DateTime.fromMillisecondsSinceEpoch(raw);
    return DateTime.now().difference(dismissedAt) < _snoozeDuration;
  }

  Future<void> snooze() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissedAtKey, DateTime.now().millisecondsSinceEpoch);
    state = state.copyWith(snoozed: true);
  }

  Future<PwaInstallOutcome> install() async {
    final outcome = await _bridge.promptInstall();
    _refreshFromBridge();
    if (outcome == PwaInstallOutcome.accepted) {
      state = state.copyWith(isStandalone: true, canPrompt: false);
    }
    return outcome;
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }
}

final pwaInstallBridgeProvider = Provider<PwaInstallBridge>((ref) {
  return const PwaInstallBridge();
});

final pwaInstallControllerProvider =
    StateNotifierProvider<PwaInstallController, PwaInstallState>((ref) {
  return PwaInstallController(ref.watch(pwaInstallBridgeProvider));
});
