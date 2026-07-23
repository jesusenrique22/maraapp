import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/brand_config.dart';
import '../../theme/mara_theme.dart';
import '../pwa_install_bridge.dart';
import '../pwa_install_controller.dart';

/// Host de instalación PWA: banner contextual + hoja de guía iOS.
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
            left: 14,
            right: 14,
            // Por encima del NavigationBar (~68) + SafeArea
            bottom: 78,
            child: SafeArea(
              top: false,
              bottom: false,
              child: _PwaInstallCard(
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            content: Text('Farma Express quedó en tu pantalla de inicio'),
            backgroundColor: MaraColors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      case PwaInstallOutcome.dismissed:
        break;
      case PwaInstallOutcome.unavailable:
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Abre el menú del navegador y elige “Instalar app”',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _PwaInstallCard extends StatefulWidget {
  const _PwaInstallCard({
    required this.isIos,
    required this.onInstall,
    required this.onLater,
  });

  final bool isIos;
  final VoidCallback onInstall;
  final VoidCallback onLater;

  @override
  State<_PwaInstallCard> createState() => _PwaInstallCardState();
}

class _PwaInstallCardState extends State<_PwaInstallCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.35),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

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
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            decoration: BoxDecoration(
              color: MaraColors.navy,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MaraColors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        BrandConfig.appName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.isIos
                            ? 'Añádela a tu pantalla de inicio'
                            : 'Instálala y ábrela como app',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: widget.onLater,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Luego', style: TextStyle(fontSize: 12.5)),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: widget.onInstall,
                  style: FilledButton.styleFrom(
                    backgroundColor: MaraColors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  child: Text(widget.isIos ? 'Cómo' : 'Instalar'),
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        22 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MaraColors.textTertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Instalar Farma Express en iPhone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Safari no permite un botón de instalación automática. Hazlo en 3 pasos:',
            style: TextStyle(
              color: MaraColors.textSecondary.withValues(alpha: 0.95),
              height: 1.4,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          const _IosStep(
            number: '1',
            title: 'Toca Compartir',
            subtitle: 'El ícono □↑ en la barra de Safari',
          ),
          const _IosStep(
            number: '2',
            title: 'Añadir a pantalla de inicio',
            subtitle: 'Desplázate en el menú hasta esa opción',
          ),
          const _IosStep(
            number: '3',
            title: 'Confirma “Añadir”',
            subtitle: 'Farma Express quedará en tu inicio',
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IosStep extends StatelessWidget {
  const _IosStep({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  final String number;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: MaraColors.greenLight,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: MaraColors.greenDark,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: MaraColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
