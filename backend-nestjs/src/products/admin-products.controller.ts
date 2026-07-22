import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/types/auth-user';
import {
  CreateProductDto,
  StockMovementDto,
  UpdateProductDto,
} from './dto/product.dto';
import { ProductsService } from './products.service';

@Controller('admin/products')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll(
    @Query('limit') limit?: string,
    @Query('offset') offset?: string,
    @Query('search') search?: string,
  ) {
    const parsedLimit = limit ? Number.parseInt(limit, 10) : 120;
    const parsedOffset = offset ? Number.parseInt(offset, 10) : 0;
    return this.productsService.findAllAdmin({
      limit: Number.isFinite(parsedLimit) ? parsedLimit : 120,
      offset: Number.isFinite(parsedOffset) ? parsedOffset : 0,
      search: search?.trim() || undefined,
    });
  }

  @Post()
  create(@Body() dto: CreateProductDto, @CurrentUser() user: AuthUser) {
    return this.productsService.create(dto, user.id);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.productsService.update(id, dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.productsService.remove(id);
  }

  @Post(':id/stock')
  addStock(
    @Param('id') id: string,
    @Body() dto: StockMovementDto,
    @CurrentUser() user: AuthUser,
  ) {
    return this.productsService.addStock(
      id,
      dto.quantity,
      user.id,
      dto.branchId,
      dto.reference,
      dto.notes,
    );
  }
}
