import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/mara_theme.dart';
import '../pwa_install_bridge.dart';
import '../pwa_install_controller.dart';

/// Host de instalación PWA: aviso discreto + guía iOS.
class PwaInstallHost extends ConsumerStatefulWidget {
  const PwaInstallHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PwaInstallHost> createState() => _PwaInstallHostState();
}

class _PwaInstallHostState extends ConsumerState<PwaInstallHost> {
  bool _iosSheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pwaInstallControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (state.shouldShowBanner)
          Positioned(
            left: 16,
            right: 16,
            bottom: 78,
            child: SafeArea(
              top: false,
              bottom: false,
              child: _PwaInstallBar(
                isIos: state.shouldShowIosGuide,
                onInstall: () => _onInstall(state),
                onLater: () =>
                    ref.read(pwaInstallControllerProvider.notifier).snooze(),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _onInstall(PwaInstallState state) async {
    if (state.shouldShowIosGuide) {
      if (_iosSheetOpen) return;
      _iosSheetOpen = true;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => const _IosInstallSheet(),
      );
      _iosSheetOpen = false;
      return;
    }

    final outcome =
        await ref.read(pwaInstallControllerProvider.notifier).install();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    switch (outcome) {
      case PwaInstallOutcome.accepted:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Listo — ya está en tu inicio'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case PwaInstallOutcome.dismissed:
        break;
      case PwaInstallOutcome.unavailable:
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Usa el menú del navegador → Instalar app'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _PwaInstallBar extends StatefulWidget {
  const _PwaInstallBar({
    required this.isIos,
    required this.onInstall,
    required this.onLater,
  });

  final bool isIos;
  final VoidCallback onInstall;
  final VoidCallback onLater;

  @override
  State<_PwaInstallBar> createState() => _PwaInstallBarState();
}

class _PwaInstallBarState extends State<_PwaInstallBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.12),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: MaraColors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          shadowColor: MaraColors.textPrimary.withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: MaraColors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.isIos
                        ? 'Añadir a pantalla de inicio'
                        : 'Instalar Farma Express',
                    style: const TextStyle(
                      color: MaraColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: -0.15,
                      height: 1.2,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onInstall,
                  style: TextButton.styleFrom(
                    foregroundColor: MaraColors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  child: Text(widget.isIos ? 'Ver cómo' : 'Instalar'),
                ),
                IconButton(
                  onPressed: widget.onLater,
                  tooltip: 'Ahora no',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: MaraColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IosInstallSheet extends StatelessWidget {
  const _IosInstallSheet();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: MaraColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'En Safari',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toca Compartir y luego “Añadir a pantalla de inicio”.',
            style: TextStyle(
              color: MaraColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          const _QuietStep(label: 'Compartir', detail: 'Ícono □↑ abajo'),
          const SizedBox(height: 14),
          const _QuietStep(
            label: 'Añadir a pantalla de inicio',
            detail: 'En el menú de Safari',
          ),
          const SizedBox(height: 14),
          const _QuietStep(label: 'Añadir', detail: 'Confirma y listo'),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: MaraColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietStep extends StatelessWidget {
  const _QuietStep({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
              color: MaraColors.textPrimary,
            ),
          ),
        ),
        Text(
          detail,
          style: const TextStyle(
            fontSize: 13,
            color: MaraColors.textTertiary,
          ),
        ),
      ],
    );
  }
}
