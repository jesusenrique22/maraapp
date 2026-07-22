import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_redirect.dart';
import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/mara_logo.dart';
import '../../admin/providers/admin_providers.dart';
import '../../patient/presentation/patient_telemedicine_screen.dart';

class MaraLoginScreen extends ConsumerStatefulWidget {
  const MaraLoginScreen({
    super.key,
    required this.loginContext,
    this.redirect,
  });

  final MaraLoginContext loginContext;
  final String? redirect;

  @override
  ConsumerState<MaraLoginScreen> createState() => _MaraLoginScreenState();
}

/// Alias legacy.
typedef MedicPlusLoginScreen = MaraLoginScreen;

class _MaraLoginScreenState extends ConsumerState<MaraLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isRegisterMode = false;
  bool _obscure = true;
  bool _submitting = false;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _anim.dispose();
    super.dispose();
  }

  bool _forceLoginForm = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    bool ok;
    if (_isRegisterMode) {
      ok = await ref.read(adminAuthProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    } else {
      ok = await ref.read(adminAuthProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      ref.invalidate(patientDoctorsProvider);
      ref.invalidate(patientAppointmentsProvider);

      final role = ref.read(adminAuthProvider).session?.user.role;
      final destination = AuthRedirect.defaultAfterLogin(
        role: role,
        context: widget.loginContext,
        redirect: widget.redirect,
      );

      if (!mounted) return;
      context.go(destination);
    } else {
      final error = ref.read(adminAuthProvider).error ?? 'Credenciales incorrectas';
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

  Future<void> _continueWithSession() async {
    final destination = AuthRedirect.defaultAfterLogin(
      role: 'CUSTOMER',
      context: widget.loginContext,
      redirect: widget.redirect,
    );
    if (widget.loginContext == MaraLoginContext.medicPlus) {
      ref.invalidate(patientDoctorsProvider);
      ref.invalidate(patientAppointmentsProvider);
    }
    if (mounted) context.go(destination);
  }

  Future<void> _switchAccount() async {
    await ref.read(adminAuthProvider.notifier).logout();
    if (mounted) setState(() => _forceLoginForm = true);
  }

  _LoginCopy get _copy => switch (widget.loginContext) {
        MaraLoginContext.staff => const _LoginCopy(
            badge: 'PERSONAL FARMA EXPRESS',
            badgeIcon: Icons.admin_panel_settings_outlined,
            badgeColor: Color(0xFFFFE8D6),
            badgeTextColor: MaraColors.greenDark,
            title: 'Acceso Personal',
            registerTitle: 'Acceso Personal',
            subtitle: 'Panel administrativo y consultas médicas.',
            registerSubtitle: 'Contacta al administrador para obtener acceso.',
            accent: MaraColors.green,
            sideTitle: 'Panel\nProfesional',
            sideBody:
                'Gestión integrada de inventario, consultas médicas, pacientes y farmacia Farma Express.',
            sideIcon: Icons.dashboard_rounded,
          ),
        _ => const _LoginCopy(
            badge: 'CUENTA FARMA EXPRESS',
            badgeIcon: Icons.all_inclusive_rounded,
            badgeColor: Color(0xFFFFE8D6),
            badgeTextColor: MaraColors.greenDark,
            title: 'Inicia sesión en Farma Express',
            registerTitle: 'Crea tu cuenta en Farma Express',
            subtitle:
                'Una sola cuenta para comprar en farmacia, panadería y más, y agendar consultas en Medic Express.',
            registerSubtitle:
                'Regístrate gratis y accede a compras rápidas, retiro en sucursal y consultas médicas virtuales.',
            accent: MaraColors.green,
            sideTitle: 'Todo Farma Express\nen un solo lugar',
            sideBody:
                'Compra en tienda, recibe medicamentos y consulta con médicos en vivo a través de Medic Express, desde Farma Express.',
            sideIcon: Icons.auto_awesome_rounded,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(adminAuthProvider);
    final wide = MediaQuery.sizeOf(context).width > 800;
    final copy = _copy;

    if (auth.isRestoring || auth.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF1F5F9),
        body: Center(
          child: CircularProgressIndicator(color: MaraColors.navyMid),
        ),
      );
    }

    final canContinueWithSession = auth.isAuthenticated &&
        auth.session?.user.role == 'CUSTOMER' &&
        widget.loginContext == MaraLoginContext.medicPlus &&
        !_forceLoginForm;

    if (canContinueWithSession) {
      final user = auth.session!.user;
      return Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const MaraLogo(height: 48, dark: false),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: MaraShadows.elevated,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: copy.badgeColor,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: copy.badgeTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.loginContext == MaraLoginContext.medicPlus
                              ? '¿Entrar a Medic Express?'
                              : 'Ya iniciaste sesión',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Continuar con ${user.email}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: MaraColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tu sesión sigue activa — no necesitas escribir tu contraseña otra vez.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: MaraColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _continueWithSession,
                            style: FilledButton.styleFrom(
                              backgroundColor: copy.accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              widget.loginContext == MaraLoginContext.medicPlus
                                  ? 'Entrar a Medic Express'
                                  : 'Continuar a la tienda',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _switchAccount,
                          child: const Text('Usar otra cuenta'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Volver a la tienda'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          if (wide) Expanded(child: _SidePromoPanel(copy: copy)),
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
                                child: MaraLogo(height: 48, dark: false)),
                            const SizedBox(height: 24),
                          ],
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.shade100.withValues(alpha: 0.3),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: copy.badgeColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(copy.badgeIcon,
                                            color: copy.badgeTextColor, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          copy.badge,
                                          style: TextStyle(
                                            color: copy.badgeTextColor,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    _isRegisterMode
                                        ? copy.registerTitle
                                        : copy.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 24,
                                      color: MaraColors.textPrimary,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isRegisterMode
                                        ? copy.registerSubtitle
                                        : copy.subtitle,
                                    style: const TextStyle(
                                      color: MaraColors.textSecondary,
                                      height: 1.4,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  if (_isRegisterMode &&
                                      widget.loginContext != MaraLoginContext.staff) ...[
                                    _InputField(
                                      controller: _nameController,
                                      label: 'Nombre completo',
                                      icon: Icons.person_outline_rounded,
                                      accentColor: copy.accent,
                                      validator: (v) => v?.trim().isEmpty == true
                                          ? 'Ingresa tu nombre'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // Email field
                                  _InputField(
                                    controller: _emailController,
                                    label: 'Correo electrónico',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    accentColor: copy.accent,
                                    validator: (v) => v?.trim().isEmpty == true
                                        ? 'Ingresa tu correo'
                                        : null,
                                  ),
                                  const SizedBox(height: 14),

                                  // Password field
                                  _InputField(
                                    controller: _passwordController,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscure,
                                    accentColor: copy.accent,
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
                                    validator: (v) => (v?.length ?? 0) < 6
                                        ? 'Mínimo 6 caracteres'
                                        : null,
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  const SizedBox(height: 24),

                                  // Submit Button
                                  _SubmitButton(
                                    loading: _submitting,
                                    label: _isRegisterMode ? 'Registrarme' : 'Entrar',
                                    accent: copy.accent,
                                    onTap: _submit,
                                  ),
                                  const SizedBox(height: 16),

                                  if (widget.loginContext != MaraLoginContext.staff)
                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _isRegisterMode = !_isRegisterMode;
                                          });
                                        },
                                        child: Text(
                                          _isRegisterMode
                                              ? '¿Ya tienes una cuenta? Inicia sesión'
                                              : '¿No tienes cuenta? Regístrate aquí',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: copy.accent,
                                          ),
                                        ),
                                      ),
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
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.arrow_back_rounded,
                                        size: 16, color: MaraColors.textPrimary),
                                    SizedBox(width: 8),
                                    Text(
                                      'Volver a la tienda',
                                      style: TextStyle(
                                        color: MaraColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    required this.accentColor,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final Color accentColor;

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
        fontSize: 14.5,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: MaraColors.textSecondary,
          fontSize: 13.5,
        ),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _LoginCopy {
  const _LoginCopy({
    required this.badge,
    required this.badgeIcon,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.title,
    required this.registerTitle,
    required this.subtitle,
    required this.registerSubtitle,
    required this.accent,
    required this.sideTitle,
    required this.sideBody,
    required this.sideIcon,
  });

  final String badge;
  final IconData badgeIcon;
  final Color badgeColor;
  final Color badgeTextColor;
  final String title;
  final String registerTitle;
  final String subtitle;
  final String registerSubtitle;
  final Color accent;
  final String sideTitle;
  final String sideBody;
  final IconData sideIcon;
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.loading,
    required this.label,
    required this.onTap,
    required this.accent,
  });

  final bool loading;
  final String label;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }
}

class _SidePromoPanel extends StatelessWidget {
  const _SidePromoPanel({required this.copy});

  final _LoginCopy copy;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: copy.accent == MaraColors.violet
              ? const [
                  Color(0xFF3B0764),
                  Color(0xFF6B21A8),
                  Color(0xFF8B5CF6),
                ]
              : const [
                  Color(0xFF0B1E40),
                  Color(0xFF1E3A8A),
                  MaraColors.green,
                ],
        ),
      ),
      child: Stack(
        children: [
          // Orbs
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -50,
            bottom: -50,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const MaraLogo(height: 52, dark: true),
                const SizedBox(height: 64),
                Icon(copy.sideIcon, color: Colors.white, size: 52),
                const SizedBox(height: 24),
                Text(
                  copy.sideTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 38,
                    height: 1.1,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  copy.sideBody,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    height: 1.5,
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
