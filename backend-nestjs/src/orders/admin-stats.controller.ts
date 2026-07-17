import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { Roles } from '../common/decorators/roles.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { AdminStatsService } from './admin-stats.service';

@Controller('admin/stats')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class AdminStatsController {
  constructor(private readonly statsService: AdminStatsService) {}

  @Get()
  getDashboard(@Query('days') days?: string) {
    const parsed = days ? Number.parseInt(days, 10) : 30;
    return this.statsService.getDashboard(
      Number.isFinite(parsed) ? parsed : 30,
    );
  }
}
