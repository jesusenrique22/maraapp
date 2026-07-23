/// Stub: fuera de web no hay instalación PWA.
class PwaInstallBridge {
  const PwaInstallBridge();

  bool get isSupported => false;
  bool get isStandalone => false;
  bool get canPrompt => false;
  bool get isIosSafariHint => false;

  void Function() onChange(void Function() listener) => () {};

  Future<PwaInstallOutcome> promptInstall() async => PwaInstallOutcome.unavailable;
}

enum PwaInstallOutcome {
  accepted,
  dismissed,
  unavailable,
}
