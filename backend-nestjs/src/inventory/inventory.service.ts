import { Injectable } from '@nestjs/common';
import { InventoryMovementType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class InventoryService {
  constructor(private readonly prisma: PrismaService) {}

  movementDelta(type: InventoryMovementType, quantity: number): number {
    switch (type) {
      case InventoryMovementType.ENTRY:
        return quantity;
      case InventoryMovementType.EXIT:
      case InventoryMovementType.SALE:
      case InventoryMovementType.WASTE:
        return -Math.abs(quantity);
      case InventoryMovementType.ADJUSTMENT:
        return quantity;
      default:
        return 0;
    }
  }

  async getStock(productId: string, branchId?: string): Promise<number> {
    const where: Prisma.InventoryMovementWhereInput = { productId };
    if (branchId) {
      where.branchId = branchId;
    }

    const movements = await this.prisma.inventoryMovement.findMany({
      where,
      select: { type: true, quantity: true },
    });

    return movements.reduce(
      (total, movement) =>
        total + this.movementDelta(movement.type, movement.quantity),
      0,
    );
  }

  async getStockMap(
    productIds: string[],
    branchId?: string,
  ): Promise<Map<string, number>> {
    if (!productIds.length) {
      return new Map();
    }

    const where: Prisma.InventoryMovementWhereInput = {
      productId: { in: productIds },
    };
    if (branchId) {
      where.branchId = branchId;
    }

    const movements = await this.prisma.inventoryMovement.findMany({
      where,
      select: { productId: true, type: true, quantity: true },
    });

    const stockMap = new Map<string, number>();

    for (const movement of movements) {
      const current = stockMap.get(movement.productId) ?? 0;
      stockMap.set(
        movement.productId,
        current + this.movementDelta(movement.type, movement.quantity),
      );
    }

    return stockMap;
  }

  async getTotalStockMap(productIds: string[]): Promise<Map<string, number>> {
    return this.getStockMap(productIds);
  }

  async registerMovement(input: {
    productId: string;
    branchId?: string;
    type: InventoryMovementType;
    quantity: number;
    userId?: string;
    reference?: string;
    notes?: string;
  }) {
    return this.prisma.inventoryMovement.create({
      data: {
        productId: input.productId,
        branchId: input.branchId,
        type: input.type,
        quantity: input.quantity,
        userId: input.userId,
        reference: input.reference,
        notes: input.notes,
      },
    });
  }

  formatProduct<T extends Record<string, unknown>>(
    product: T,
    stock: number,
  ) {
    const price = Number(product.price);
    const discountPercent =
      product.discountPercent != null ? Number(product.discountPercent) : null;
    const finalPrice =
      discountPercent != null
        ? Number((price * (1 - discountPercent / 100)).toFixed(2))
        : price;

    return {
      ...product,
      price,
      discountPercent,
      finalPrice,
      stock,
      inStock: stock > 0,
    };
  }

  productInclude = {
    category: {
      select: { id: true, name: true, slug: true },
    },
  } satisfies Prisma.ProductInclude;
}
