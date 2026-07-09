import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { FulfillmentType, InventoryMovementType, OrderStatus } from '@prisma/client';
import { InventoryService } from '../inventory/inventory.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class OrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
  ) {}

  private generateOrderNumber(): string {
    const date = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const suffix = Math.random().toString(36).slice(2, 8).toUpperCase();
    return `MP-${date}-${suffix}`;
  }

  private computeUnitPrice(price: number, discountPercent: number | null) {
    if (discountPercent != null && discountPercent > 0) {
      return Number((price * (1 - discountPercent / 100)).toFixed(2));
    }
    return price;
  }

  async create(userId: string, dto: CreateOrderDto) {
    const requested = new Map<string, number>();
    for (const item of dto.items) {
      requested.set(
        item.productId,
        (requested.get(item.productId) ?? 0) + item.quantity,
      );
    }

    const productIds = [...requested.keys()];
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, isActive: true },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException('Uno o más productos no están disponibles');
    }

    const productMap = new Map(products.map((product) => [product.id, product]));

    if (!dto.branchId) {
      throw new BadRequestException('Selecciona una sucursal');
    }

    const branch = await this.prisma.branch.findFirst({
      where: { id: dto.branchId, isActive: true },
    });
    if (!branch) {
      throw new BadRequestException('Sucursal no válida');
    }

    const stockMap = await this.inventory.getStockMap(productIds, dto.branchId);

    const lineItems: Array<{
      productId: string;
      productName: string;
      productSku: string;
      unitPrice: number;
      quantity: number;
      lineTotal: number;
    }> = [];

    let subtotal = 0;

    for (const [productId, quantity] of requested.entries()) {
      const product = productMap.get(productId)!;
      const stock = stockMap.get(productId) ?? 0;

      if (stock < quantity) {
        throw new BadRequestException(
          `Stock insuficiente para "${product.name}" (disponible: ${stock})`,
        );
      }

      const unitPrice = this.computeUnitPrice(
        Number(product.price),
        product.discountPercent,
      );
      const lineTotal = Number((unitPrice * quantity).toFixed(2));
      subtotal += lineTotal;

      lineItems.push({
        productId,
        productName: product.name,
        productSku: product.sku,
        unitPrice,
        quantity,
        lineTotal,
      });
    }

    const fulfillmentType = dto.fulfillmentType ?? FulfillmentType.DELIVERY;

    if (fulfillmentType === FulfillmentType.DELIVERY && !dto.deliveryAddress?.trim()) {
      throw new BadRequestException('Ingresa tu dirección de entrega');
    }

    const branchId = branch.id;

    const deliveryFee =
      fulfillmentType === FulfillmentType.PICKUP ? 0 : subtotal > 20 ? 0 : 2;
    const total = Number((subtotal + deliveryFee).toFixed(2));
    subtotal = Number(subtotal.toFixed(2));

    const orderNumber = this.generateOrderNumber();

    const order = await this.prisma.$transaction(async (tx) => {
      const created = await tx.order.create({
        data: {
          orderNumber,
          userId,
          branchId,
          fulfillmentType,
          status: OrderStatus.CONFIRMED,
          subtotal,
          deliveryFee,
          total,
          deliveryAddress:
            fulfillmentType === FulfillmentType.PICKUP
              ? null
              : dto.deliveryAddress?.trim() || null,
          notes: dto.notes?.trim() || null,
          items: {
            create: lineItems.map((item) => ({
              productId: item.productId,
              productName: item.productName,
              productSku: item.productSku,
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              lineTotal: item.lineTotal,
            })),
          },
        },
        include: {
          items: {
            include: {
              product: {
                select: {
                  id: true,
                  imageUrl: true,
                  category: { select: { slug: true } },
                },
              },
            },
          },
        },
      });

      for (const item of lineItems) {
        await tx.inventoryMovement.create({
          data: {
            productId: item.productId,
            branchId: dto.branchId,
            type: InventoryMovementType.SALE,
            quantity: item.quantity,
            userId,
            reference: orderNumber,
            notes: 'Venta por pedido online',
          },
        });
      }

      return created;
    });

    return this.formatOrder(order);
  }

  async findMine(userId: string) {
    const orders = await this.prisma.order.findMany({
      where: { userId },
      include: {
        branch: {
          select: { id: true, name: true, address: true, city: true, phone: true },
        },
        items: {
          include: {
            product: {
              select: {
                id: true,
                imageUrl: true,
                category: { select: { slug: true } },
              },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return orders.map((order) => this.formatOrder(order));
  }

  async findByIdForUser(id: string, userId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id, userId },
      include: {
        branch: {
          select: { id: true, name: true, address: true, city: true, phone: true },
        },
        items: {
          include: {
            product: {
              select: {
                id: true,
                imageUrl: true,
                category: { select: { slug: true } },
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException('Pedido no encontrado');
    }

    return this.formatOrder(order);
  }

  async findAllAdmin() {
    const orders = await this.prisma.order.findMany({
      include: {
        user: { select: { id: true, name: true, email: true } },
        items: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    return orders.map((order) => ({
      ...this.formatOrder(order),
      customer: order.user,
    }));
  }

  private formatOrder(
    order: {
      id: string;
      orderNumber: string;
      status: OrderStatus;
      fulfillmentType: FulfillmentType;
      subtotal: unknown;
      deliveryFee: unknown;
      total: unknown;
      deliveryAddress: string | null;
      notes: string | null;
      createdAt: Date;
      updatedAt: Date;
      branch?: {
        id: string;
        name: string;
        address: string;
        city: string;
        phone: string | null;
      } | null;
      items: Array<{
        id: string;
        productId: string;
        productName: string;
        productSku: string;
        unitPrice: unknown;
        quantity: number;
        lineTotal: unknown;
        product?: {
          id: string;
          imageUrl: string | null;
          category: { slug: string };
        } | null;
      }>;
    },
  ) {
    return {
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      fulfillmentType: order.fulfillmentType,
      subtotal: Number(order.subtotal),
      deliveryFee: Number(order.deliveryFee),
      total: Number(order.total),
      deliveryAddress: order.deliveryAddress,
      branch: order.branch
        ? {
            id: order.branch.id,
            name: order.branch.name,
            address: order.branch.address,
            city: order.branch.city,
            phone: order.branch.phone,
          }
        : null,
      notes: order.notes,
      createdAt: order.createdAt.toISOString(),
      updatedAt: order.updatedAt.toISOString(),
      items: order.items.map((item) => ({
        id: item.id,
        productId: item.productId,
        productName: item.productName,
        productSku: item.productSku,
        unitPrice: Number(item.unitPrice),
        quantity: item.quantity,
        lineTotal: Number(item.lineTotal),
        imageUrl: item.product?.imageUrl ?? null,
        categorySlug: item.product?.category.slug ?? null,
      })),
    };
  }
}
