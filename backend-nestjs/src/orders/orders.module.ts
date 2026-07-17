import { Module } from '@nestjs/common';
import { InventoryModule } from '../inventory/inventory.module';
import { AdminOrdersController } from './admin-orders.controller';
import { AdminStatsController } from './admin-stats.controller';
import { AdminStatsService } from './admin-stats.service';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [InventoryModule],
  controllers: [OrdersController, AdminOrdersController, AdminStatsController],
  providers: [OrdersService, AdminStatsService],
})
export class OrdersModule {}
