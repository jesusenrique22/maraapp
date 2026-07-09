import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async check() {
    const startedAt = Date.now();

    await this.prisma.$queryRaw`SELECT 1`;

    const categoriesCount = await this.prisma.category.count();

    return {
      status: 'ok',
      service: 'maraplus-api',
      database: {
        connected: true,
        latencyMs: Date.now() - startedAt,
        categoriesCount,
      },
      timestamp: new Date().toISOString(),
    };
  }
}
