import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    // Conexión en background: el API escucha antes y pasa el health check de Render.
    void this.$connect().catch((error) => {
      console.error('Prisma connect error (retry on first query):', error);
    });
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
