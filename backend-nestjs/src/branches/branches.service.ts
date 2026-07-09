import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class BranchesService {
  constructor(private readonly prisma: PrismaService) {}

  private formatBranch(branch: {
    id: string;
    name: string;
    slug: string;
    address: string;
    city: string;
    state: string | null;
    phone: string | null;
    whatsapp: string | null;
    latitude: unknown;
    longitude: unknown;
    openingHours: string | null;
    isMain: boolean;
    isActive: boolean;
    sortOrder: number;
    createdAt: Date;
    updatedAt: Date;
  }) {
    return {
      id: branch.id,
      name: branch.name,
      slug: branch.slug,
      address: branch.address,
      city: branch.city,
      state: branch.state,
      phone: branch.phone,
      whatsapp: branch.whatsapp,
      latitude: branch.latitude != null ? Number(branch.latitude) : null,
      longitude: branch.longitude != null ? Number(branch.longitude) : null,
      openingHours: branch.openingHours,
      isMain: branch.isMain,
      isActive: branch.isActive,
      sortOrder: branch.sortOrder,
      createdAt: branch.createdAt.toISOString(),
      updatedAt: branch.updatedAt.toISOString(),
    };
  }

  findAllPublic() {
    return this.prisma.branch
      .findMany({
        where: { isActive: true },
        orderBy: [{ isMain: 'desc' }, { sortOrder: 'asc' }, { name: 'asc' }],
      })
      .then((branches) => branches.map((b) => this.formatBranch(b)));
  }

  findAllAdmin() {
    return this.prisma.branch
      .findMany({
        orderBy: [{ isMain: 'desc' }, { sortOrder: 'asc' }, { name: 'asc' }],
      })
      .then((branches) => branches.map((b) => this.formatBranch(b)));
  }

  async findById(id: string) {
    const branch = await this.prisma.branch.findUnique({ where: { id } });
    if (!branch) {
      throw new NotFoundException('Sucursal no encontrada');
    }
    return this.formatBranch(branch);
  }

  async create(data: {
    name: string;
    slug: string;
    address: string;
    city: string;
    state?: string;
    phone?: string;
    whatsapp?: string;
    latitude?: number;
    longitude?: number;
    openingHours?: string;
    isMain?: boolean;
    isActive?: boolean;
    sortOrder?: number;
  }) {
    if (data.isMain) {
      await this.prisma.branch.updateMany({
        where: { isMain: true },
        data: { isMain: false },
      });
    }

    const branch = await this.prisma.branch.create({
      data: {
        name: data.name.trim(),
        slug: data.slug.trim().toLowerCase(),
        address: data.address.trim(),
        city: data.city.trim(),
        state: data.state?.trim(),
        phone: data.phone?.trim(),
        whatsapp: data.whatsapp?.trim(),
        latitude: data.latitude,
        longitude: data.longitude,
        openingHours: data.openingHours?.trim(),
        isMain: data.isMain ?? false,
        isActive: data.isActive ?? true,
        sortOrder: data.sortOrder ?? 0,
      },
    });

    return this.formatBranch(branch);
  }

  async update(
    id: string,
    data: Partial<{
      name: string;
      slug: string;
      address: string;
      city: string;
      state: string;
      phone: string;
      whatsapp: string;
      latitude: number;
      longitude: number;
      openingHours: string;
      isMain: boolean;
      isActive: boolean;
      sortOrder: number;
    }>,
  ) {
    await this.findById(id);

    if (data.isMain) {
      await this.prisma.branch.updateMany({
        where: { isMain: true, NOT: { id } },
        data: { isMain: false },
      });
    }

    const branch = await this.prisma.branch.update({
      where: { id },
      data: {
        ...data,
        name: data.name?.trim(),
        slug: data.slug?.trim().toLowerCase(),
        address: data.address?.trim(),
        city: data.city?.trim(),
        state: data.state?.trim(),
        phone: data.phone?.trim(),
        whatsapp: data.whatsapp?.trim(),
        openingHours: data.openingHours?.trim(),
      },
    });

    return this.formatBranch(branch);
  }

  async remove(id: string) {
    await this.findById(id);
    const branch = await this.prisma.branch.update({
      where: { id },
      data: { isActive: false },
    });
    return this.formatBranch(branch);
  }
}
