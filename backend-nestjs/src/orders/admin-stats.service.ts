import { Injectable } from '@nestjs/common';
import { OrderStatus } from '@prisma/client';
import { InventoryService } from '../inventory/inventory.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AdminStatsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
  ) {}

  /** Conteos ligeros para el Inicio del admin (no descarga catálogo completo). */
  async getOverview() {
    const [products, categories, banners, doctors, patients, branches] =
      await Promise.all([
        this.prisma.product.count({ where: { isActive: true } }),
        this.prisma.category.count(),
        this.prisma.banner.count(),
        this.prisma.user.count({ where: { role: 'DOCTOR', isActive: true } }),
        this.prisma.user.count({ where: { role: 'CUSTOMER', isActive: true } }),
        this.prisma.branch.count({ where: { isActive: true } }),
      ]);

    return {
      products,
      categories,
      banners,
      doctors,
      patients,
      branches,
      apiOnline: true,
    };
  }

  async getDashboard(days = 30) {
    const safeDays = Math.min(Math.max(days, 7), 90);
    const from = new Date();
    from.setHours(0, 0, 0, 0);
    from.setDate(from.getDate() - (safeDays - 1));

    const soldStatuses: OrderStatus[] = [
      OrderStatus.CONFIRMED,
      OrderStatus.PROCESSING,
      OrderStatus.DELIVERED,
    ];

    const [
      productsCount,
      bannersCount,
      doctorsCount,
      patientsCount,
      branchesCount,
      ordersInRange,
      previousOrders,
      topItems,
    ] = await Promise.all([
      this.prisma.product.count({ where: { isActive: true } }),
      this.prisma.banner.count({ where: { isActive: true } }),
      this.prisma.user.count({ where: { role: 'DOCTOR', isActive: true } }),
      this.prisma.user.count({ where: { role: 'CUSTOMER', isActive: true } }),
      this.prisma.branch.count({ where: { isActive: true } }),
      this.prisma.order.findMany({
        where: { createdAt: { gte: from } },
        select: {
          id: true,
          status: true,
          fulfillmentType: true,
          total: true,
          createdAt: true,
          branchId: true,
          branch: { select: { name: true } },
        },
        orderBy: { createdAt: 'asc' },
      }),
      this.prisma.order.findMany({
        where: {
          createdAt: {
            gte: new Date(from.getTime() - safeDays * 24 * 60 * 60 * 1000),
            lt: from,
          },
          status: { in: soldStatuses },
        },
        select: { total: true },
      }),
      this.prisma.orderItem.groupBy({
        by: ['productId', 'productName', 'productSku'],
        where: {
          order: {
            createdAt: { gte: from },
            status: { in: soldStatuses },
          },
        },
        _sum: { quantity: true, lineTotal: true },
        orderBy: { _sum: { quantity: 'desc' } },
        take: 10,
      }),
    ]);

    const soldOrders = ordersInRange.filter((o) =>
      soldStatuses.includes(o.status),
    );
    const cancelledOrders = ordersInRange.filter(
      (o) => o.status === OrderStatus.CANCELLED,
    );

    const revenue = soldOrders.reduce((sum, o) => sum + Number(o.total), 0);
    const previousRevenue = previousOrders.reduce(
      (sum, o) => sum + Number(o.total),
      0,
    );
    const orderCount = soldOrders.length;
    const averageTicket = orderCount > 0 ? revenue / orderCount : 0;
    const cancelRate =
      ordersInRange.length > 0
        ? (cancelledOrders.length / ordersInRange.length) * 100
        : 0;

    const revenueDeltaPct =
      previousRevenue > 0
        ? ((revenue - previousRevenue) / previousRevenue) * 100
        : revenue > 0
          ? 100
          : 0;

    const byDayMap = new Map<string, { revenue: number; orders: number }>();
    for (let i = 0; i < safeDays; i++) {
      const d = new Date(from);
      d.setDate(from.getDate() + i);
      byDayMap.set(d.toISOString().slice(0, 10), { revenue: 0, orders: 0 });
    }
    for (const order of soldOrders) {
      const key = order.createdAt.toISOString().slice(0, 10);
      const bucket = byDayMap.get(key);
      if (!bucket) continue;
      bucket.revenue += Number(order.total);
      bucket.orders += 1;
    }

    const salesByDay = [...byDayMap.entries()].map(([date, v]) => ({
      date,
      revenue: Number(v.revenue.toFixed(2)),
      orders: v.orders,
    }));

    const byStatusMap = new Map<string, number>();
    for (const order of ordersInRange) {
      byStatusMap.set(order.status, (byStatusMap.get(order.status) ?? 0) + 1);
    }
    const byStatus = [...byStatusMap.entries()].map(([status, count]) => ({
      status,
      count,
    }));

    const byFulfillmentMap = new Map<string, number>();
    for (const order of soldOrders) {
      byFulfillmentMap.set(
        order.fulfillmentType,
        (byFulfillmentMap.get(order.fulfillmentType) ?? 0) + 1,
      );
    }
    const byFulfillment = [...byFulfillmentMap.entries()].map(
      ([type, count]) => ({ type, count }),
    );

    const byBranchMap = new Map<
      string,
      { name: string; revenue: number; orders: number }
    >();
    for (const order of soldOrders) {
      const key = order.branchId ?? 'sin-sucursal';
      const name = order.branch?.name ?? 'Sin sucursal';
      const current = byBranchMap.get(key) ?? {
        name,
        revenue: 0,
        orders: 0,
      };
      current.revenue += Number(order.total);
      current.orders += 1;
      byBranchMap.set(key, current);
    }
    const byBranch = [...byBranchMap.values()]
      .map((b) => ({
        name: b.name,
        revenue: Number(b.revenue.toFixed(2)),
        orders: b.orders,
      }))
      .sort((a, b) => b.revenue - a.revenue);

    const topProducts = topItems.map((item) => ({
      productId: item.productId,
      name: item.productName,
      sku: item.productSku,
      unitsSold: item._sum.quantity ?? 0,
      revenue: Number(Number(item._sum.lineTotal ?? 0).toFixed(2)),
    }));

    const watchProductIds = [
      ...new Set(topProducts.map((p) => p.productId)),
    ];
    const stockMap = await this.inventory.getStockMap(watchProductIds);
    const lowStock = topProducts
      .map((p) => ({
        id: p.productId,
        name: p.name,
        sku: p.sku,
        stock: stockMap.get(p.productId) ?? 0,
      }))
      .filter((p) => p.stock <= 10)
      .sort((a, b) => a.stock - b.stock)
      .slice(0, 8);

    const funnel = {
      catalogProducts: productsCount,
      customers: patientsCount,
      ordersCreated: ordersInRange.length,
      ordersSold: orderCount,
      delivered: ordersInRange.filter((o) => o.status === OrderStatus.DELIVERED)
        .length,
      cancelled: cancelledOrders.length,
    };

    const insights = this.buildInsights({
      revenue,
      revenueDeltaPct,
      orderCount,
      averageTicket,
      cancelRate,
      topProducts,
      lowStock,
      byFulfillment,
      byBranch,
    });

    return {
      periodDays: safeDays,
      from: from.toISOString(),
      catalog: {
        products: productsCount,
        banners: bannersCount,
        doctors: doctorsCount,
        patients: patientsCount,
        branches: branchesCount,
      },
      kpis: {
        revenue: Number(revenue.toFixed(2)),
        orders: orderCount,
        averageTicket: Number(averageTicket.toFixed(2)),
        cancelRate: Number(cancelRate.toFixed(1)),
        revenueDeltaPct: Number(revenueDeltaPct.toFixed(1)),
      },
      salesByDay,
      byStatus,
      byFulfillment,
      byBranch,
      topProducts,
      lowStock,
      funnel,
      insights,
    };
  }

  private buildInsights(input: {
    revenue: number;
    revenueDeltaPct: number;
    orderCount: number;
    averageTicket: number;
    cancelRate: number;
    topProducts: Array<{ name: string; unitsSold: number; revenue: number }>;
    lowStock: Array<{ name: string; stock: number }>;
    byFulfillment: Array<{ type: string; count: number }>;
    byBranch: Array<{ name: string; revenue: number; orders: number }>;
  }): string[] {
    const tips: string[] = [];

    if (input.revenueDeltaPct >= 10) {
      tips.push(
        `Ventas ↑ ${input.revenueDeltaPct.toFixed(0)}% vs el período anterior. Mantén stock de los top productos.`,
      );
    } else if (input.revenueDeltaPct <= -10) {
      tips.push(
        `Ventas ↓ ${Math.abs(input.revenueDeltaPct).toFixed(0)}% vs el período anterior. Revisa promociones y banners activos.`,
      );
    } else if (input.orderCount === 0) {
      tips.push(
        'Aún no hay pedidos vendidos en este período. Impulsa el home con ofertas y productos destacados.',
      );
    } else {
      tips.push(
        `Rendimiento estable: ${input.orderCount} pedidos y ticket promedio de $${input.averageTicket.toFixed(2)}.`,
      );
    }

    if (input.topProducts.length > 0) {
      const top = input.topProducts[0];
      tips.push(
        `Más vendido: ${top.name} (${top.unitsSold} uds · $${top.revenue.toFixed(2)}). Prioriza su reposición.`,
      );
    }

    if (input.lowStock.length > 0) {
      tips.push(
        `${input.lowStock.length} top producto(s) con stock ≤ 10. Revisa inventario para no perder ventas.`,
      );
    }

    if (input.cancelRate >= 15) {
      tips.push(
        `Tasa de cancelación alta (${input.cancelRate.toFixed(0)}%). Revisa tiempos de preparación y stock al confirmar.`,
      );
    }

    const pickup =
      input.byFulfillment.find((f) => f.type === 'PICKUP')?.count ?? 0;
    const delivery =
      input.byFulfillment.find((f) => f.type === 'DELIVERY')?.count ?? 0;
    if (pickup + delivery > 0) {
      const pickupShare = Math.round((pickup / (pickup + delivery)) * 100);
      tips.push(
        pickupShare >= 60
          ? `El ${pickupShare}% es retiro en sucursal. Refuerza horarios y señalización de pickup.`
          : `Delivery concentra la demanda. Optimiza zonas y umbral de envío gratis.`,
      );
    }

    if (input.byBranch.length > 1) {
      const leader = input.byBranch[0];
      tips.push(
        `Sucursal líder: ${leader.name} ($${leader.revenue.toFixed(2)} · ${leader.orders} pedidos). Replica su mix en otras.`,
      );
    }

    return tips.slice(0, 6);
  }
}
