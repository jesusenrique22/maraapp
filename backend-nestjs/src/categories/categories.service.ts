import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CategoriesService {
  constructor(private readonly prisma: PrismaService) {}

  findAllPublic() {
    return this.prisma.category.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        name: true,
        slug: true,
        description: true,
        iconUrl: true,
        sortOrder: true,
      },
    });
  }

  findAllAdmin() {
    return this.prisma.category.findMany({
      orderBy: { sortOrder: 'asc' },
    });
  }

  async findById(id: string) {
    const category = await this.prisma.category.findUnique({ where: { id } });
    if (!category) {
      throw new NotFoundException('Categoría no encontrada');
    }
    return category;
  }

  create(data: {
    name: string;
    slug: string;
    description?: string;
    iconUrl?: string;
    sortOrder?: number;
  }) {
    return this.prisma.category.create({ data });
  }

  async update(
    id: string,
    data: Partial<{
      name: string;
      slug: string;
      description: string;
      iconUrl: string;
      sortOrder: number;
      isActive: boolean;
    }>,
  ) {
    await this.findById(id);
    return this.prisma.category.update({ where: { id }, data });
  }
}
