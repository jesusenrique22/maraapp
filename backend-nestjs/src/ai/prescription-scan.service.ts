import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InventoryService } from '../inventory/inventory.service';
import { PrismaService } from '../prisma/prisma.service';
import { UploadService } from '../upload/upload.service';
import { resolveGeminiScanApiKey, userFacingGeminiError } from './gemini.config';
import { parsePrescriptionImageWithGemini } from './prescription-gemini.parser';
import { matchPrescriptionToInventory } from './prescription-inventory.matcher';
import type { PrescriptionScanResponse } from './prescription-scan.types';

@Injectable()
export class PrescriptionScanService {
  private readonly logger = new Logger(PrescriptionScanService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
    private readonly uploadService: UploadService,
  ) {}

  async scanFromUpload(file: Express.Multer.File): Promise<PrescriptionScanResponse> {
    this.uploadService.validateImage(file);

    const apiKey = resolveGeminiScanApiKey(this.configService);
    if (!apiKey) {
      throw new ServiceUnavailableException(
        'Escáner de recetas no configurado. Agrega GEMINI_SCAN_API_KEY en el servidor.',
      );
    }

    const mimeType = file.mimetype || 'image/jpeg';
    const parsed = await parsePrescriptionImageWithGemini(
      apiKey,
      file.buffer,
      mimeType,
    );

    if (!parsed.ok) {
      const message = parsed.failure
        ? userFacingGeminiError(parsed.failure)
        : 'No pudimos leer la receta. Intenta con una foto más nítida y bien iluminada.';
      throw new BadRequestException(message);
    }

    const prescription = parsed.data;

    if (prescription.medications.length === 0) {
      throw new BadRequestException(
        'No detectamos medicamentos en la imagen. Verifica que la receta sea legible.',
      );
    }

    this.logger.log(
      `Receta parseada: ${prescription.medications.length} medicamento(s), confianza ${prescription.confidence}`,
    );

    const items = await matchPrescriptionToInventory(
      this.prisma,
      this.inventory,
      prescription.medications,
    );

    const summary = {
      totalMedications: items.length,
      foundExact: items.filter((i) => i.matchStatus === 'exact').length,
      foundSimilar: items.filter((i) => i.matchStatus === 'similar').length,
      notFound: items.filter((i) => i.matchStatus === 'not_found').length,
    };

    return { prescription, items, summary };
  }
}
