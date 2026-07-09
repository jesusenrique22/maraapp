import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { searchBakery, searchBeverages } from './catalog-client';
import type { CatalogSearchResult } from './catalog.types';

@Injectable()
export class CatalogService {
  private readonly logger = new Logger(CatalogService.name);

  constructor(private readonly config: ConfigService) {}

  async searchBeverages(query: string, limit = 10): Promise<CatalogSearchResult> {
    const apiKey = this.config.get<string>('RAPIDAPI_KEY');
    const result = await searchBeverages(query, { apiKey, limit });

    if (result.source === 'fallback') {
      this.logger.warn(
        `Bebidas: usando catálogo local para "${query}" (DummyJSON/Walmart no disponibles).`,
      );
    } else {
      this.logger.debug(`Bebidas desde ${result.source} para "${query}"`);
    }

    return result;
  }

  async searchBakery(query: string, limit = 10): Promise<CatalogSearchResult> {
    const result = await searchBakery(query, { limit });

    if (result.source === 'fallback') {
      this.logger.warn(
        `Panadería: usando catálogo local para "${query}" (UPCitemdb no disponible).`,
      );
    } else {
      this.logger.debug(`Panadería desde ${result.source} para "${query}"`);
    }

    return result;
  }
}
