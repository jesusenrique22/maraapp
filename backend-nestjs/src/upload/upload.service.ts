import { BadRequestException, Injectable } from '@nestjs/common';
import { existsSync, mkdirSync } from 'fs';
import { extname, join } from 'path';
import { randomUUID } from 'crypto';

const ALLOWED_MIME_TYPES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/bmp',
  'image/svg+xml',
  'image/heic',
  'image/heif',
]);

const ALLOWED_EXTENSIONS = new Set([
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
  '.gif',
  '.bmp',
  '.svg',
  '.heic',
  '.heif',
]);

@Injectable()
export class UploadService {
  private readonly uploadDir = join(process.cwd(), 'uploads', 'products');

  ensureUploadDir() {
    if (!existsSync(this.uploadDir)) {
      mkdirSync(this.uploadDir, { recursive: true });
    }
  }

  validateImage(file?: Express.Multer.File) {
    if (!file) {
      throw new BadRequestException('Debes seleccionar una imagen');
    }

    const extension = extname(file.originalname).toLowerCase();

    if (!ALLOWED_MIME_TYPES.has(file.mimetype) && !ALLOWED_EXTENSIONS.has(extension)) {
      throw new BadRequestException(
        'Formato no permitido. Usa JPG, PNG, WEBP, GIF, BMP o SVG',
      );
    }

    if (file.size > 5 * 1024 * 1024) {
      throw new BadRequestException('La imagen no puede superar 5 MB');
    }
  }

  buildPublicUrl(filename: string) {
    const configured = process.env.PUBLIC_API_URL?.replace(/\/+$/, '');
    const base = configured ?? `http://127.0.0.1:${process.env.PORT ?? 3000}`;
    return `${base}/uploads/products/${filename}`;
  }

  generateFilename(originalName: string) {
    const extension = extname(originalName).toLowerCase() || '.jpg';
    return `${Date.now()}-${randomUUID()}${extension}`;
  }

  get uploadPath() {
    return this.uploadDir;
  }
}
