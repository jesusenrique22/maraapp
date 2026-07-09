import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/mara_theme.dart';

/// Tokens visuales suaves del panel admin — un solo acento (verde Mara).
class AdminSoft {
  static const background = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const tintGreen = Color(0xFFEEFBF4);
  static const tintBlue = Color(0xFFF3F6FC);

  static BoxDecoration cardDecoration({double radius = 14}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: MaraColors.textPrimary.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration introCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [tintGreen, tintBlue],
    ),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: MaraColors.green.withValues(alpha: 0.12)),
  );

  static BoxDecoration metricTile = BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: MaraColors.textPrimary.withValues(alpha: 0.05)),
  );

  static BoxDecoration iconWell = BoxDecoration(
    color: MaraColors.green.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(10),
  );
}

class AdminKpiStrip extends StatelessWidget {
  const AdminKpiStrip({
    super.key,
    required this.items,
  });

  final List<AdminKpiItem> items;

  @override
  Widget build(BuildContext context) {
    return AdminMetricBand(
      metrics: items
          .map((item) => AdminMetric(label: item.label, value: int.tryParse(item.value) ?? 0))
          .toList(),
    );
  }
}

class AdminMetric {
  const AdminMetric({required this.label, required this.value});

  final String label;
  final int value;
}

class AdminMetricBand extends StatelessWidget {
  const AdminMetricBand({super.key, required this.metrics});

  final List<AdminMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;

    if (narrow) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: metrics.map((metric) {
            return SizedBox(
              width: (MediaQuery.sizeOf(context).width - horizontalPadding(context) - 10) / 2,
              child: _metricTile(metric),
            );
          }).toList(),
        ),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _metricTile(metrics[i])),
        ],
      ],
    );
  }

  double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w > 900 ? 80 : 40;
  }

  Widget _metricTile(AdminMetric metric) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AdminSoft.metricTile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${metric.value}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: MaraColors.textPrimary,
              letterSpacing: -0.8,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: const TextStyle(
              fontSize: 12,
              color: MaraColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDirectoryItem {
  const AdminDirectoryItem({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String subtitle;
  final String count;
  final VoidCallback onTap;
  final IconData? icon;
}

class AdminDirectoryPanel extends StatelessWidget {
  const AdminDirectoryPanel({super.key, required this.items});

  final List<AdminDirectoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AdminSoft.cardDecoration(radius: 14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            AdminDirectoryRow(item: items[i]),
            if (i < items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: MaraColors.textPrimary.withValues(alpha: 0.05),
                indent: 68,
                endIndent: 20,
              ),
          ],
        ],
      ),
    );
  }
}

class AdminDirectoryRow extends StatefulWidget {
  const AdminDirectoryRow({super.key, required this.item});

  final AdminDirectoryItem item;

  @override
  State<AdminDirectoryRow> createState() => _AdminDirectoryRowState();
}

class _AdminDirectoryRowState extends State<AdminDirectoryRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? AdminSoft.tintGreen.withValues(alpha: 0.45) : Colors.white,
        child: InkWell(
          onTap: widget.item.onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                if (widget.item.icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AdminSoft.iconWell,
                    child: Icon(
                      widget.item.icon,
                      size: 18,
                      color: MaraColors.greenDark.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: MaraColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.item.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: MaraColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.item.count,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MaraColors.textSecondary.withValues(alpha: 0.75),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _hovered
                        ? MaraColors.green.withValues(alpha: 0.1)
                        : MaraColors.textPrimary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: _hovered ? MaraColors.greenDark : MaraColors.textTertiary,
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

class AdminPageIntro extends StatelessWidget {
  const AdminPageIntro({
    super.key,
    required this.userName,
    required this.apiOnline,
  });

  final String userName;
  final bool apiOnline;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String _formattedDate() {
    const weekdays = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} ${now.day} de ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: AdminSoft.introCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()}, $firstName',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: MaraColors.textPrimary,
                        letterSpacing: -0.7,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _capitalize(_formattedDate()),
                      style: const TextStyle(
                        fontSize: 14,
                        color: MaraColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (apiOnline ? MaraColors.green : MaraColors.rose).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (apiOnline ? MaraColors.green : MaraColors.rose).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: apiOnline ? MaraColors.green : MaraColors.rose,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      apiOnline ? 'En línea' : 'Offline',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: apiOnline ? MaraColors.greenDark : MaraColors.rose,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}

class AdminInlineActions extends StatelessWidget {
  const AdminInlineActions({
    super.key,
    required this.onAddProduct,
    required this.onViewStore,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onViewStore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: onAddProduct,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar producto'),
          style: FilledButton.styleFrom(
            backgroundColor: MaraColors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onViewStore,
          icon: const Icon(Icons.storefront_outlined, size: 17),
          label: const Text('Ver tienda'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MaraColors.textSecondary,
            side: BorderSide(color: MaraColors.textPrimary.withValues(alpha: 0.1)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class AdminKpiItem {
  const AdminKpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

/// @deprecated Usar [AdminDirectoryPanel] en el dashboard.
class AdminModuleCard extends StatefulWidget {
  const AdminModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String countLabel;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<AdminModuleCard> createState() => _AdminModuleCardState();
}

class _AdminModuleCardState extends State<AdminModuleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha: 0.35)
                      : const Color(0xFFE8EEF5),
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: widget.color.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : MaraShadows.card,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.color.withValues(alpha: 0.16),
                            widget.color.withValues(alpha: 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: MaraColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: MaraColors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            widget.countLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: widget.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _hovered
                                ? widget.color.withValues(alpha: 0.12)
                                : const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: widget.color.withValues(alpha: _hovered ? 1 : 0.65),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboardHeader extends StatelessWidget {
  const AdminDashboardHeader({
    super.key,
    required this.userName,
    required this.apiOnline,
  });

  final String userName;
  final bool apiOnline;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: MaraColors.navy,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MaraColors.green.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    MaraColors.navyAccent.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -0.6,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Administra catálogo, publicidad, equipo y sucursales desde un solo lugar.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: apiOnline ? MaraColors.green : MaraColors.rose,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (apiOnline ? MaraColors.green : MaraColors.rose)
                                .withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      apiOnline ? 'En línea' : 'Sin conexión',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSecondaryActions extends StatelessWidget {
  const AdminSecondaryActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            onPressed: () => context.go('/admin/products/new'),
            icon: Icons.add_rounded,
            label: 'Nuevo producto',
            filled: true,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            onPressed: () => context.go('/home'),
            icon: Icons.storefront_outlined,
            label: 'Ver tienda',
            filled: false,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.filled,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          backgroundColor: MaraColors.navyMid,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: MaraColors.textSecondary,
        side: const BorderSide(color: Color(0xFFE8EEF5)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class AdminQuickActionTile extends StatelessWidget {
  const AdminQuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8EEF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: MaraColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: MaraColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminHeroBanner extends StatelessWidget {
  const AdminHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: MaraColors.gradientNavy,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: MaraColors.navy.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Super Admin MaraPlus',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 16),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class AdminSectionTitle extends StatelessWidget {
  const AdminSectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: MaraColors.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: MaraColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

class AdminEntityCard extends StatelessWidget {
  const AdminEntityCard({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.meta,
    this.badge,
    this.trailing,
    this.onTap,
  });

  final Widget avatar;
  final String title;
  final String subtitle;
  final String? meta;
  final Widget? badge;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: MaraShadows.card,
          ),
          child: narrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatar,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(subtitle, style: const TextStyle(fontSize: 12, color: MaraColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (badge != null) badge!,
                      ],
                    ),
                    if (meta != null) ...[
                      const SizedBox(height: 10),
                      Text(meta!, style: const TextStyle(fontSize: 12, color: MaraColors.navyMid, fontWeight: FontWeight.w700)),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 12),
                      trailing!,
                    ],
                  ],
                )
              : Row(
                  children: [
                    avatar,
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: MaraColors.textSecondary)),
                          if (meta != null) ...[
                            const SizedBox(height: 6),
                            Text(meta!, style: const TextStyle(fontSize: 12, color: MaraColors.navyMid, fontWeight: FontWeight.w700)),
                          ],
                        ],
                      ),
                    ),
                    if (badge != null) badge!,
                    if (trailing != null) trailing!,
                  ],
                ),
        ),
      ),
    );
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.active, this.activeLabel = 'Activo', this.inactiveLabel = 'Inactivo'});

  final bool active;
  final String activeLabel;
  final String inactiveLabel;

  @override
  Widget build(BuildContext context) {
    final color = active ? MaraColors.green : MaraColors.rose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        active ? activeLabel : inactiveLabel,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MaraColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: MaraColors.navyMid.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MaraColors.textSecondary, height: 1.4),
            ),
            if (action != null) ...[const SizedBox(height: 18), action!],
          ],
        ),
      ),
    );
  }
}

class AdminFab extends StatelessWidget {
  const AdminFab({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: color ?? MaraColors.navyMid,
      elevation: 4,
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
