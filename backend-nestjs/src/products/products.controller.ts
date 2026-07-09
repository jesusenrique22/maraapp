import { Controller, Get, Param, Query } from '@nestjs/common';
import { ProductsService } from './products.service';

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll(
    @Query('category') category?: string,
    @Query('search') search?: string,
    @Query('branchId') branchId?: string,
  ) {
    return this.productsService.findAllPublic({ category, search, branchId });
  }

  @Get('featured/list')
  findFeatured(@Query('branchId') branchId?: string) {
    return this.productsService.findFeaturedPublic(branchId);
  }

  @Get('home/list')
  findHomePreview(@Query('branchId') branchId?: string) {
    return this.productsService.findHomePreviewPublic(branchId);
  }

  @Get(':id/availability')
  getAvailability(@Param('id') id: string) {
    return this.productsService.getAvailability(id);
  }

  @Get(':id')
  findOne(
    @Param('id') id: string,
    @Query('branchId') branchId?: string,
  ) {
    return this.productsService.findById(id, branchId);
  }
}
