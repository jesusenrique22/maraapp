import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InventoryMovementType, Prisma } from '@prisma/client';
import { InventoryService } from '../inventory/inventory.service';
import { PrismaService } from '../prisma/prisma.service';
import { CreateProductDto, UpdateProductDto } from './dto/product.dto';

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
  ) {}

  async findAllPublic(filters: {
    category?: string;
    search?: string;
    branchId?: string;
  }) {
    const where: Prisma.ProductWhereInput = {
      isActive: true,
      category: { isActive: true },
    };

    if (filters.category) {
      where.category = { slug: filters.category, isActive: true };
    }

    if (filters.search) {
      where.OR = [
        { name: { contains: filters.search, mode: 'insensitive' } },
        { sku: { contains: filters.search, mode: 'insensitive' } },
        { description: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    const products = await this.prisma.product.findMany({
      where,
      include: this.inventory.productInclude,
      orderBy: { name: 'asc' },
    });

    const stockMap = await this.inventory.getStockMap(
      products.map((p) => p.id),
      filters.branchId,
    );

    return products.map((product) =>
      this.inventory.formatProduct(
        { ...product, price: Number(product.price) },
        stockMap.get(product.id) ?? 0,
      ),
    );
  }

  /** Vista rápida del home: pocos productos por categoría (evita cargar miles). */
  async findHomePreviewPublic(branchId?: string, perCategory = 8) {
    const categories = await this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });

    const products = (
      await Promise.all(
        categories.map((category) =>
          this.prisma.product.findMany({
            where: {
              isActive: true,
              categoryId: category.id,
              category: { isActive: true },
            },
            include: this.inventory.productInclude,
            orderBy: [{ isFeatured: 'desc' }, { name: 'asc' }],
            take: perCategory,
          }),
        ),
      )
    ).flat();

    const stockMap = await this.inventory.getStockMap(
      products.map((p) => p.id),
      branchId,
    );

    return products.map((product) =>
      this.inventory.formatProduct(
        { ...product, price: Number(product.price) },
        stockMap.get(product.id) ?? 0,
      ),
    );
  }

  async findFeaturedPublic(branchId?: string) {
    const products = await this.prisma.product.findMany({
      where: { isActive: true, isFeatured: true, category: { isActive: true } },
      include: this.inventory.productInclude,
      orderBy: { name: 'asc' },
      take: 12,
    });

    const stockMap = await this.inventory.getStockMap(
      products.map((p) => p.id),
      branchId,
    );

    return products.map((product) =>
      this.inventory.formatProduct(
        { ...product, price: Number(product.price) },
        stockMap.get(product.id) ?? 0,
      ),
    );
  }

  async findAllAdmin() {
    const products = await this.prisma.product.findMany({
      include: this.inventory.productInclude,
      orderBy: { createdAt: 'desc' },
    });

    const stockMap = await this.inventory.getTotalStockMap(
      products.map((p) => p.id),
    );

    return products.map((product) =>
      this.inventory.formatProduct(
        { ...product, price: Number(product.price) },
        stockMap.get(product.id) ?? 0,
      ),
    );
  }

  async findById(id: string, branchId?: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: this.inventory.productInclude,
    });

    if (!product) {
      throw new NotFoundException('Producto no encontrado');
    }

    const stock = await this.inventory.getStock(id, branchId);

    return this.inventory.formatProduct(
      { ...product, price: Number(product.price) },
      stock,
    );
  }

  private async resolveMainBranchId() {
    const branch = await this.prisma.branch.findFirst({
      where: { isMain: true, isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: { id: true },
    });
    return branch?.id;
  }

  async create(dto: CreateProductDto, userId: string) {
    const category = await this.prisma.category.findUnique({
      where: { id: dto.categoryId },
    });

    if (!category) {
      throw new BadRequestException('Categoría inválida');
    }

    const skuTaken = await this.prisma.product.findUnique({
      where: { sku: dto.sku.trim() },
      select: { id: true },
    });

    if (skuTaken) {
      throw new ConflictException(
        `Ya existe un producto con el SKU "${dto.sku.trim()}"`,
      );
    }

    let product;
    try {
      product = await this.prisma.product.create({
        data: {
          sku: dto.sku.trim(),
          name: dto.name,
          description: dto.description,
          price: dto.price,
          imageUrl: dto.imageUrl,
          categoryId: dto.categoryId,
          discountPercent: dto.discountPercent,
          isFeatured: dto.isFeatured ?? false,
        },
        include: this.inventory.productInclude,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException('Ya existe un producto con ese SKU');
      }
      throw error;
    }

    if (dto.initialStock && dto.initialStock > 0) {
      const branchId = await this.resolveMainBranchId();
      await this.inventory.registerMovement({
        productId: product.id,
        branchId,
        type: InventoryMovementType.ENTRY,
        quantity: dto.initialStock,
        userId,
        reference: 'INITIAL_STOCK',
        notes: 'Stock inicial al crear producto',
      });
    }

    const stock = await this.inventory.getTotalStockMap([product.id]);

    return this.inventory.formatProduct(
      { ...product, price: Number(product.price) },
      stock.get(product.id) ?? 0,
    );
  }

  async update(id: string, dto: UpdateProductDto) {
    await this.findById(id);

    if (dto.categoryId) {
      const category = await this.prisma.category.findUnique({
        where: { id: dto.categoryId },
      });
      if (!category) {
        throw new BadRequestException('Categoría inválida');
      }
    }

    const product = await this.prisma.product.update({
      where: { id },
      data: dto,
      include: this.inventory.productInclude,
    });

    const stockMap = await this.inventory.getTotalStockMap([id]);

    return this.inventory.formatProduct(
      { ...product, price: Number(product.price) },
      stockMap.get(id) ?? 0,
    );
  }

  async remove(id: string) {
    await this.findById(id);

    const product = await this.prisma.product.update({
      where: { id },
      data: { isActive: false },
      include: this.inventory.productInclude,
    });

    const stockMap = await this.inventory.getTotalStockMap([id]);

    return this.inventory.formatProduct(
      { ...product, price: Number(product.price) },
      stockMap.get(id) ?? 0,
    );
  }

  async addStock(
    id: string,
    quantity: number,
    userId: string,
    branchId?: string,
    reference?: string,
    notes?: string,
  ) {
    await this.findById(id);

    const resolvedBranchId = branchId ?? (await this.resolveMainBranchId());
    if (!resolvedBranchId) {
      throw new BadRequestException('No hay sucursal disponible para registrar stock');
    }

    await this.inventory.registerMovement({
      productId: id,
      branchId: resolvedBranchId,
      type: InventoryMovementType.ENTRY,
      quantity,
      userId,
      reference,
      notes,
    });

    return this.findById(id);
  }

  async getAvailability(productId: string) {
    await this.findById(productId);

    const branches = await this.prisma.branch.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
    });

    const results: any[] = [];
    for (const branch of branches) {
      const stock = await this.inventory.getStock(productId, branch.id);
      results.push({
        branch,
        stock,
        inStock: stock > 0,
      });
    }

    return results;
  }
}
