import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { AppModule } from './app.module';
import { UploadService } from './upload/upload.service';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  const uploadService = app.get(UploadService);
  uploadService.ensureUploadDir();

  app.enableCors({ origin: true });

  // Flutter web corre en otro puerto; las imágenes subidas necesitan CORS explícito.
  app.use('/uploads', (req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');

    if (req.method === 'OPTIONS') {
      res.sendStatus(204);
      return;
    }

    next();
  });

  app.useStaticAssets(join(process.cwd(), 'uploads'), {
    prefix: '/uploads/',
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT ?? 3000;
  await app.listen(port, '0.0.0.0');

  console.log(`Farma Express API running on http://localhost:${port}`);
}
bootstrap();
