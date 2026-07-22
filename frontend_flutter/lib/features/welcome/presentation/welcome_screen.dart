import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/auth_redirect.dart';
import '../../../core/theme/mara_theme.dart';
import '../../../shared/widgets/mara_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              MaraColors.lightBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const MaraLogo(height: 96, showTagline: true),
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: MaraColors.navy.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 40,
                        color: MaraColors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bienvenido a Farma Express',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              color: MaraColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Farmacia, panadería, charcutería y bodegón · 24 horas. '
                        'Todo lo que buscas en un solo lugar.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(
                              color: MaraColors.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Ir a la tienda'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(
                      AuthRedirect.medicPlusLoginPath(redirect: '/medic-plus'),
                    ),
                    child: const Text('Medic Plus — Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
