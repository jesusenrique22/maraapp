import { Injectable, NotFoundException } from '@nestjs/common';
import { BannerPlacement, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBannerDto, UpdateBannerDto } from './dto/banner.dto';

@Injectable()
export class BannersService {
  constructor(private readonly prisma: PrismaService) {}

  findPublic(placement?: BannerPlacement) {
    const where: Prisma.BannerWhereInput = { isActive: true };
    if (placement) where.placement = placement;

    return this.prisma.banner.findMany({
      where,
      orderBy: { sortOrder: 'asc' },
      select: {
        id: true,
        title: true,
        subtitle: true,
        imageUrl: true,
        backgroundColor: true,
        textColor: true,
        badgeText: true,
        buttonText: true,
        linkUrl: true,
        placement: true,
        sortOrder: true,
      },
    });
  }

  findAllAdmin() {
    return this.prisma.banner.findMany({ orderBy: { sortOrder: 'asc' } });
  }

  async findById(id: string) {
    const banner = await this.prisma.banner.findUnique({ where: { id } });
    if (!banner) throw new NotFoundException('Banner no encontrado');
    return banner;
  }

  create(dto: CreateBannerDto) {
    return this.prisma.banner.create({ data: dto });
  }

  async update(id: string, dto: UpdateBannerDto) {
    await this.findById(id);
    return this.prisma.banner.update({ where: { id }, data: dto });
  }

  async remove(id: string) {
    await this.findById(id);
    return this.prisma.banner.update({
      where: { id },
      data: { isActive: false },
    });
  }
}
