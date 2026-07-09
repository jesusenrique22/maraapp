import { Controller, Get, Query } from '@nestjs/common';
import { BannerPlacement } from '@prisma/client';
import { BannersService } from './banners.service';

@Controller('banners')
export class BannersController {
  constructor(private readonly bannersService: BannersService) {}

  @Get()
  findAll(@Query('placement') placement?: BannerPlacement) {
    return this.bannersService.findPublic(placement);
  }
}
