import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/mara_theme.dart';
import '../domain/admin_models.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminStatsScreen extends ConsumerWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(adminSalesDashboardProvider);
    final period = ref.watch(adminSalesPeriodProvider);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width > 900 ? 40.0 : 20.0;

    return AdminShell(
      title: 'Estadísticas',
      currentIndex: 6,
      child: RefreshIndicator(
        color: MaraColors.green,
        onRefresh: () async {
          ref.invalidate(adminSalesDashboardProvider);
          ref.invalidate(adminStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            28,
            horizontalPadding,
            80,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: dashAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(80),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, _) => _ErrorCard(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(adminSalesDashboardProvider),
                ),
                data: (dash) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      periodDays: period,
                      onPeriodChanged: (days) {
                        ref.read(adminSalesPeriodProvider.notifier).state = days;
                      },
                    ),
                    const SizedBox(height: 22),
                    _KpiGrid(kpis: dash.kpis),
                    const SizedBox(height: 22),
                    _SectionTitle('Flujo operativo'),
                    const SizedBox(height: 12),
                    _FunnelCard(funnel: dash.funnel),
                    const SizedBox(height: 22),
                    _SectionTitle('Ventas en el tiempo'),
                    const SizedBox(height: 12),
                    _RevenueChartCard(days: dash.salesByDay),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final sideBySide = constraints.maxWidth >= 820;
                        final top = _TopProductsCard(products: dash.topProducts);
                        final insights = _InsightsCard(insights: dash.insights);
                        if (!sideBySide) {
                          return Column(
                            children: [
                              top,
                              const SizedBox(height: 16),
                              insights,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: top),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: insights),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final sideBySide = constraints.maxWidth >= 820;
                        final fulfillment = _FulfillmentCard(
                          items: dash.byFulfillment,
                        );
                        final status = _StatusCard(items: dash.byStatus);
                        if (!sideBySide) {
                          return Column(
                            children: [
                              fulfillment,
                              const SizedBox(height: 16),
                              status,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: fulfillment),
                            const SizedBox(width: 16),
                            Expanded(child: status),
                          ],
                        );
                      },
                    ),
                    if (dash.byBranch.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionTitle('Por sucursal'),
                      const SizedBox(height: 12),
                      _BranchCard(branches: dash.byBranch),
                    ],
                    if (dash.lowStock.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionTitle('Alerta de stock (top vendidos)'),
                      const SizedBox(height: 12),
                      _LowStockCard(products: dash.lowStock),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({
    required this.periodDays,
    required this.onPeriodChanged,
  });

  final int periodDays;
  final ValueChanged<int> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AdminSoft.introCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Panel de decisiones',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ventas, flujo de pedidos y recomendaciones para actuar.',
            style: TextStyle(
              fontSize: 13,
              color: MaraColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [7, 30, 90].map((d) {
              final selected = periodDays == d;
              return ChoiceChip(
                label: Text('$d días'),
                selected: selected,
                onSelected: (_) => onPeriodChanged(d),
                selectedColor: MaraColors.green,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : MaraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? MaraColors.green
                      : MaraColors.textPrimary.withValues(alpha: 0.1),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: MaraColors.green.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: MaraColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final AdminSalesKpis kpis;

  @override
  Widget build(BuildContext context) {
    final delta = kpis.revenueDeltaPct;
    final deltaLabel = delta >= 0
        ? '+${delta.toStringAsFixed(0)}%'
        : '${delta.toStringAsFixed(0)}%';

    final items = [
      _KpiData('Ventas', '\$${kpis.revenue.toStringAsFixed(2)}', deltaLabel),
      _KpiData('Pedidos', '${kpis.orders}', 'vendidos'),
      _KpiData(
        'Ticket promedio',
        '\$${kpis.averageTicket.toStringAsFixed(2)}',
        'por pedido',
      ),
      _KpiData(
        'Cancelación',
        '${kpis.cancelRate.toStringAsFixed(0)}%',
        'del total',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 700
            ? 4
            : constraints.maxWidth >= 480
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 3.2 : 1.55,
          ),
          itemBuilder: (context, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: AdminSoft.metricTile,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MaraColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: MaraColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.hint,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i == 0
                          ? (kpis.revenueDeltaPct >= 0
                              ? MaraColors.greenDark
                              : MaraColors.rose)
                          : MaraColors.textTertiary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.hint);
  final String label;
  final String value;
  final String hint;
}

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.funnel});

  final AdminSalesFunnel funnel;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Catálogo', funnel.catalogProducts, Icons.inventory_2_outlined),
      ('Clientes', funnel.customers, Icons.people_outline),
      ('Pedidos creados', funnel.ordersCreated, Icons.receipt_long_outlined),
      ('Pedidos vendidos', funnel.ordersSold, Icons.shopping_bag_outlined),
      ('Entregados', funnel.delivered, Icons.check_circle_outline),
      ('Cancelados', funnel.cancelled, Icons.cancel_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: i == steps.length - 1 && funnel.cancelled > 0
                        ? MaraColors.rose.withValues(alpha: 0.1)
                        : AdminSoft.tintGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    steps[i].$3,
                    size: 18,
                    color: i == steps.length - 1 && funnel.cancelled > 0
                        ? MaraColors.rose
                        : MaraColors.greenDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    steps[i].$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${steps[i].$2}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: MaraColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 18, top: 4, bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    size: 14,
                    color: MaraColors.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({required this.days});

  final List<AdminSalesDay> days;

  @override
  Widget build(BuildContext context) {
    final maxY = days.fold<double>(
      0,
      (m, d) => d.revenue > m ? d.revenue : m,
    );
    final chartMax = maxY <= 0 ? 10.0 : maxY * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingresos diarios',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: days.every((d) => d.revenue == 0)
                ? const Center(
                    child: Text(
                      'Sin ventas en este período',
                      style: TextStyle(color: MaraColors.textSecondary),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: chartMax,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: MaraColors.textPrimary.withValues(alpha: 0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => Text(
                              value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(1)}k'
                                  : value.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: MaraColors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (days.length / 5).clamp(1, 14).toDouble(),
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= days.length) {
                                return const SizedBox.shrink();
                              }
                              final label = days[i].date.length >= 10
                                  ? days[i].date.substring(5)
                                  : days[i].date;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: MaraColors.textTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (var i = 0; i < days.length; i++)
                              FlSpot(i.toDouble(), days[i].revenue),
                          ],
                          isCurved: true,
                          color: MaraColors.green,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: MaraColors.green.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.products});

  final List<AdminTopProduct> products;

  @override
  Widget build(BuildContext context) {
    final maxUnits = products.fold<int>(
      1,
      (m, p) => p.unitsSold > m ? p.unitsSold : m,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Productos más vendidos',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            const Text(
              'Aún no hay ventas para rankear productos.',
              style: TextStyle(color: MaraColors.textSecondary),
            )
          else
            for (var i = 0; i < products.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: MaraColors.textTertiary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          products[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: products[i].unitsSold / maxUnits,
                            minHeight: 6,
                            backgroundColor:
                                MaraColors.textPrimary.withValues(alpha: 0.06),
                            color: MaraColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${products[i].unitsSold} uds',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: MaraColors.textPrimary,
                        ),
                      ),
                      Text(
                        '\$${products[i].revenue.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: MaraColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recomendaciones',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < insights.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AdminSoft.tintGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: MaraColors.greenDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insights[i],
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: MaraColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FulfillmentCard extends StatelessWidget {
  const _FulfillmentCard({required this.items});

  final List<AdminFulfillmentCount> items;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (s, e) => s + e.count);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery vs Pickup',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'Sin pedidos vendidos',
              style: TextStyle(color: MaraColors.textSecondary),
            )
          else
            for (final item in items) ...[
              Text(
                item.type == 'DELIVERY' ? 'Delivery' : 'Retiro en sucursal',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : item.count / total,
                  minHeight: 8,
                  backgroundColor:
                      MaraColors.textPrimary.withValues(alpha: 0.06),
                  color: item.type == 'DELIVERY'
                      ? MaraColors.navyAccent
                      : MaraColors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.count} pedidos · ${total == 0 ? 0 : ((item.count / total) * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: MaraColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.items});

  final List<AdminStatusCount> items;

  String _label(String status) {
    return switch (status) {
      'PENDING' => 'Pendiente',
      'CONFIRMED' => 'Confirmado',
      'PROCESSING' => 'En proceso',
      'DELIVERED' => 'Entregado',
      'CANCELLED' => 'Cancelado',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estados de pedido',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'Sin pedidos en el período',
              style: TextStyle(color: MaraColors.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (e) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AdminSoft.tintBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_label(e.status)} · ${e.count}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: MaraColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branches});

  final List<AdminBranchSales> branches;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < branches.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    branches[i].name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${branches[i].orders} ped. · \$${branches[i].revenue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: MaraColors.greenDark,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.products});

  final List<AdminLowStockProduct> products;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < products.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    products[i].name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MaraColors.rose.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Stock ${products[i].stock}',
                    style: const TextStyle(
                      color: MaraColors.rose,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AdminSoft.cardDecoration(),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MaraColors.rose),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(backgroundColor: MaraColors.green),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
