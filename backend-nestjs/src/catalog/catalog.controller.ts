import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { CatalogService } from './catalog.service';

@Controller('admin/catalog')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  /** Busca bebidas comerciales (DummyJSON, Walmart vía RapidAPI o catálogo local). */
  @Get('beverages/search')
  searchBeverages(
    @Query('q') query = '',
    @Query('limit') limitRaw?: string,
  ) {
    const limit = Math.min(Math.max(Number.parseInt(limitRaw ?? '10', 10) || 10, 1), 20);
    return this.catalogService.searchBeverages(query, limit);
  }

  /** Busca productos de panadería (UPCitemdb o catálogo local). */
  @Get('bakery/search')
  searchBakery(
    @Query('q') query = '',
    @Query('limit') limitRaw?: string,
  ) {
    const limit = Math.min(Math.max(Number.parseInt(limitRaw ?? '10', 10) || 10, 1), 20);
    return this.catalogService.searchBakery(query, limit);
  }
}
