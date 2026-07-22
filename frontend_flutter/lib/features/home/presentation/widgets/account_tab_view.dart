import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/auth_redirect.dart';
import '../../../../core/theme/mara_theme.dart';
import '../../../admin/providers/admin_providers.dart';
import '../../../orders/domain/order_models.dart';
import '../../../orders/providers/orders_providers.dart';

class AccountTabView extends ConsumerWidget {
  const AccountTabView({
    super.key,
    required this.onEnterMedicPlus,
    required this.onGoShopping,
  });

  final VoidCallback onEnterMedicPlus;
  final VoidCallback onGoShopping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);

    if (auth.isRestoring) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: MaraColors.navyMid),
        ),
      );
    }

    if (!auth.isAuthenticated) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: MaraColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 38,
                  color: MaraColors.navyMid,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Tu cuenta Farma Express',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: MaraColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para ver tu historial de compras, '
              'guardar tu carrito y acceder a Medic Plus con la misma cuenta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MaraColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context.go(
                  AuthRedirect.storeLoginPath(redirect: '/home?tab=account'),
                ),
                icon: const Icon(Icons.storefront_rounded),
                label: const Text('Iniciar sesión — Tienda'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => context.go(
                  AuthRedirect.medicPlusLoginPath(redirect: '/medic-plus'),
                ),
                icon: const Icon(Icons.local_hospital_outlined),
                label: const Text('Iniciar sesión — Medic Plus'),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 24),
            const Text(
              'Soporte y Contacto',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: MaraColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            const _SupportSection(),
          ]),
        ),
      );
    }

    final user = auth.session!.user;
    if (user.role != 'CUSTOMER') {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Esta sección es para clientes de la tienda. '
              'Tu rol actual es ${user.role}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: MaraColors.textSecondary),
            ),
          ),
        ),
      );
    }

    final ordersAsync = ref.watch(myOrdersProvider);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const _ProfileHeader(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.local_hospital_rounded,
                  label: 'Medic Plus',
                  color: MaraColors.green,
                  onTap: onEnterMedicPlus,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Seguir comprando',
                  color: MaraColors.green,
                  onTap: onGoShopping,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Mis compras',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: MaraColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          ordersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: MaraColors.navyMid),
              ),
            ),
            error: (_, __) => const _EmptyOrders(message: 'No se pudo cargar el historial'),
            data: (orders) {
              if (orders.isEmpty) {
                return const _EmptyOrders(
                  message: 'Aún no tienes pedidos. ¡Explora el catálogo!',
                );
              }
              return Column(
                children: orders.map((order) => _OrderCard(order: order)).toList(),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Soporte y Contacto',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: MaraColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          const _SupportSection(),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go('/home');
            },
            icon: const Icon(Icons.logout_rounded, color: MaraColors.rose),
            label: const Text(
              'Cerrar sesión',
              style: TextStyle(color: MaraColors.rose, fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(adminAuthProvider);
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    final user = auth.session!.user;
    final avatarUrl = user.avatarUrl ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=${user.email}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: MaraColors.gradientNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: MaraShadows.elevated,
      ),
      child: Row(
        children: [
          // Avatar clickable wrapper
          GestureDetector(
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _AvatarEditSheet(
                  initialAvatarUrl: avatarUrl,
                  email: user.email,
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: MaraColors.violet,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Colors.white70),
        ],
      ),
    );
  }
}

class _AvatarEditSheet extends StatefulWidget {
  const _AvatarEditSheet({required this.initialAvatarUrl, required this.email});
  final String initialAvatarUrl;
  final String email;

  @override
  State<_AvatarEditSheet> createState() => _AvatarEditSheetState();
}

class _AvatarEditSheetState extends State<_AvatarEditSheet> {
  late String _currentAvatarUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentAvatarUrl = widget.initialAvatarUrl;
  }

  void _randomize() {
    final styles = ['adventurer', 'bottts', 'pixel-art', 'fun-emoji', 'lorelei'];
    final randomStyle = styles[Random().nextInt(styles.length)];
    final randomSeed = Random().nextInt(1000000).toString();
    setState(() {
      _currentAvatarUrl = 'https://api.dicebear.com/7.x/$randomStyle/png?seed=$randomSeed';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Personaliza tu Avatar 🎨',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Genera un avatar único y guárdalo en tu perfil',
            style: TextStyle(fontSize: 13, color: MaraColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: MaraColors.violet.withValues(alpha: 0.15), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.network(
                _currentAvatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person_rounded,
                  size: 60,
                  color: MaraColors.textTertiary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: MaraColors.violet, width: 1.5),
              foregroundColor: MaraColors.violet,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: _saving ? null : _randomize,
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: const Text(
              'Randomizar Avatar 🎲',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: MaraColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    return FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: MaraColors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saving
                          ? null
                          : () async {
                              setState(() => _saving = true);
                              final ok = await ref
                                  .read(adminAuthProvider.notifier)
                                  .updateAvatar(_currentAvatarUrl);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok
                                        ? 'Avatar guardado con éxito'
                                        : 'Error al actualizar el avatar'),
                                    backgroundColor: ok ? MaraColors.green : MaraColors.rose,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: MaraShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: MaraColors.navy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MaraColors.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: MaraColors.navyMid,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order.items.length} producto${order.items.length == 1 ? '' : 's'} · '
            '\$${order.total.toStringAsFixed(2)}',
            style: const TextStyle(
              color: MaraColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (order.branch != null) ...[
            const SizedBox(height: 4),
            Text(
              'Retiro: ${order.branch!.name}',
              style: const TextStyle(fontSize: 12, color: MaraColors.green, fontWeight: FontWeight.w600),
            ),
          ] else if (order.deliveryAddress != null) ...[
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: MaraColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 36, color: MaraColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MaraColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection();

  static const _phone = '+58 212 555 0100';
  static const _email = 'soporte@farmaexpress.com';
  static const _whatsapp = '+58 414 555 0100';

  static void _copy(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MaraColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: MaraShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SupportTile(
            icon: Icons.chat_rounded,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: _whatsapp,
            onTap: () => _copy(context, _whatsapp, 'WhatsApp copiado al portapapeles'),
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
          _SupportTile(
            icon: Icons.phone_rounded,
            iconColor: MaraColors.navyMid,
            title: 'Llamar por teléfono',
            subtitle: _phone,
            onTap: () => _copy(context, _phone, 'Teléfono copiado al portapapeles'),
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),
          _SupportTile(
            icon: Icons.mail_outline_rounded,
            iconColor: MaraColors.green,
            title: 'Correo de soporte',
            subtitle: _email,
            onTap: () => _copy(context, _email, 'Correo copiado al portapapeles'),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
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
                      fontSize: 13,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MaraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.copy_all_rounded,
              color: MaraColors.textTertiary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
