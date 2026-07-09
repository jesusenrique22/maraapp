import { Controller, Get } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService) {}

  /** Respuesta rápida para el health check de Render (timeout 5s). */
  @Get()
  check() {
    return {
      status: 'ok',
      service: 'maraplus-api',
      timestamp: new Date().toISOString(),
    };
  }

  /** Verificación profunda: base de datos + latencia (no usar en Render health check). */
  @Get('ready')
  async ready() {
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
