import { Module } from '@nestjs/common';
import { AdminUploadController } from './admin-upload.controller';
import { UploadService } from './upload.service';

@Module({
  controllers: [AdminUploadController],
  providers: [UploadService],
  exports: [UploadService],
})
export class UploadModule {}
