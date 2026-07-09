import {
  Controller,
  Post,
  Body,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { AiService } from './ai.service';
import { PrescriptionScanService } from './prescription-scan.service';

interface ChatMessage {
  role: 'user' | 'model';
  text: string;
}

@Controller('ai')
export class AiController {
  constructor(
    private readonly aiService: AiService,
    private readonly prescriptionScanService: PrescriptionScanService,
  ) {}

  @Post('chat')
  async chat(
    @Body() body: { message: string; history?: ChatMessage[] },
  ) {
    const history = body.history || [];
    const response = await this.aiService.generateResponse(body.message, history);
    return { response };
  }

  /** Escanea receta médica: imagen → Gemini JSON → match inventario */
  @Post('prescription/scan')
  @UseInterceptors(
    FileInterceptor('image', {
      storage: memoryStorage(),
      limits: { fileSize: 5 * 1024 * 1024 },
    }),
  )
  async scanPrescription(@UploadedFile() file: Express.Multer.File) {
    return this.prescriptionScanService.scanFromUpload(file);
  }
}
