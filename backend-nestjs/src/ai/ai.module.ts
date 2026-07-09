import { Module } from '@nestjs/common';
import { InventoryModule } from '../inventory/inventory.module';
import { UploadModule } from '../upload/upload.module';
import { AiController } from './ai.controller';
import { AiService } from './ai.service';
import { PrescriptionScanService } from './prescription-scan.service';

@Module({
  imports: [InventoryModule, UploadModule],
  controllers: [AiController],
  providers: [AiService, PrescriptionScanService],
  exports: [AiService, PrescriptionScanService],
})
export class AiModule {}
