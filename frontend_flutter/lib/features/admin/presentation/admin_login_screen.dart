import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/mara_logo.dart';
import '../providers/admin_providers.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@farmaexpress.com');
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);
    final ok = await ref.read(adminAuthProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      context.go('/admin');
    } else {
      final error = ref.read(adminAuthProvider).error ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(error)),
            ],
          ),
          backgroundColor: MaraColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;

    return Scaffold(
      backgroundColor: MaraColors.surface,
      body: Row(
        children: [
          if (wide) Expanded(child: _BrandPanel()),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!wide) ...[
                            const Center(
                                child: MaraLogo(height: 52, dark: false)),
                            const SizedBox(height: 32),
                          ],
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: MaraShadows.elevated,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      gradient: MaraColors.gradientNavy,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.admin_panel_settings_rounded,
                                            color: Colors.white, size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'PANEL ADMIN',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Bienvenido de vuelta',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 26,
                                      color: MaraColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Gestiona productos, stock y publicidades de Farma Express.',
                                    style: TextStyle(
                                      color: MaraColors.textSecondary,
                                      height: 1.4,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Email field
                                  _FormField(
                                    controller: _emailController,
                                    label: 'Correo electrónico',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) =>
                                        v?.trim().isEmpty == true
                                            ? 'Ingresa tu correo'
                                            : null,
                                  ),
                                  const SizedBox(height: 14),
                                  // Password field
                                  _FormField(
                                    controller: _passwordController,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: MaraColors.textSecondary,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    validator: (v) =>
                                        (v?.length ?? 0) < 6
                                            ? 'Mínimo 6 caracteres'
                                            : null,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 28),
                                  // Submit
                                  _SubmitButton(
                                    loading: _submitting,
                                    onTap: _submit,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/home'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: MaraColors.navyMid
                                      .withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.storefront_outlined,
                                        size: 16, color: MaraColors.navyMid),
                                    SizedBox(width: 8),
                                    Text(
                                      'Volver a la tienda',
                                      style: TextStyle(
                                        color: MaraColors.navyMid,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── FORM FIELD ───
class _FormField extends StatelessWidget {
  const _FormField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: MaraColors.textPrimary,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: MaraColors.textSecondary,
          fontSize: 14,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MaraColors.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: MaraColors.navyMid, size: 18),
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: MaraColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaraColors.navyAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MaraColors.rose),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

// ─── SUBMIT BUTTON ───
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => !widget.loading ? _anim.forward() : null,
      onTapUp: (_) {
        _anim.reverse();
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => _anim.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.loading
                ? LinearGradient(
                    colors: [
                      MaraColors.navyMid.withValues(alpha: 0.5),
                      MaraColors.navyMid.withValues(alpha: 0.5),
                    ],
                  )
                : MaraColors.gradientNavy,
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.loading
                ? []
                : [
                    BoxShadow(
                      color: MaraColors.navyMid.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Entrar al panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── BRAND PANEL (wide layout) ───
class _BrandPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF0F2057),
            MaraColors.greenDark,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative orbs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MaraColors.navyAccent.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MaraColors.green.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const MaraLogo(height: 64, dark: true),
                const Spacer(),
                const Text(
                  'Control total\nde Farma Express',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 44,
                    height: 1.05,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Productos en tiempo real, inventario trazable y publicidades dinámicas desde un solo lugar.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.6,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 36),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeatureChip(icon: Icons.inventory_2_outlined, label: 'Inventario'),
                    _FeatureChip(icon: Icons.campaign_outlined, label: 'Publicidades'),
                    _FeatureChip(icon: Icons.insights_outlined, label: 'Stock live'),
                    _FeatureChip(icon: Icons.shield_outlined, label: 'Seguro'),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
