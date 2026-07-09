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
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import type { AuthUser } from '../common/types/auth-user';
import {
  CreateAppointmentDto,
  RejectAppointmentDto,
} from './dto/appointment.dto';
import { UpdateDoctorDto } from './dto/update-doctor.dto';
import { ConsultationsService } from './consultations.service';

@Controller('consultations')
export class ConsultationsController {
  constructor(private readonly service: ConsultationsService) {}

  @Get('doctors')
  findDoctors() {
    return this.service.findDoctors();
  }

  @Get('doctors/:doctorId/availability')
  getAvailability(
    @Param('doctorId') doctorId: string,
    @Query('date') date: string,
  ) {
    return this.service.getDoctorAvailability(doctorId, date);
  }

  @UseGuards(JwtAuthGuard)
  @Post('appointments')
  createAppointment(
    @CurrentUser() user: AuthUser,
    @Body() body: CreateAppointmentDto,
  ) {
    return this.service.createAppointment(user.id, body);
  }

  @UseGuards(JwtAuthGuard)
  @Get('appointments')
  findAppointments(@CurrentUser() user: AuthUser) {
    return this.service.findAppointments(user);
  }

  @UseGuards(JwtAuthGuard)
  @Post('appointments/:id/cancel')
  cancelAppointment(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.service.cancelAppointment(id, user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DOCTOR)
  @Post('appointments/:id/accept')
  acceptAppointment(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.service.acceptAppointment(id, user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DOCTOR)
  @Post('appointments/:id/reject')
  rejectAppointment(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body() body: RejectAppointmentDto,
  ) {
    return this.service.rejectAppointment(id, user.id, body.reason);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DOCTOR)
  @Post('appointments/:id/start')
  startAppointment(@Param('id') id: string, @CurrentUser() user: AuthUser) {
    return this.service.startAppointment(id, user.id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.DOCTOR)
  @Post('appointments/:id/finish')
  finishAppointment(
    @Param('id') id: string,
    @CurrentUser() user: AuthUser,
    @Body()
    body: {
      notes: string;
      diagnosis: string;
      prescriptionItems: any[];
    },
  ) {
    return this.service.finishAppointment(
      id,
      user.id,
      body.notes,
      body.diagnosis,
      body.prescriptionItems,
    );
  }

  // --- ADMINISTRATOR ENDPOINTS ---

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Get('admin/doctors')
  findAllDoctorsForAdmin() {
    return this.service.findAllDoctorsForAdmin();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post('admin/doctors')
  createDoctor(
    @Body()
    body: {
      email: string;
      name: string;
      specialty: string;
      bio?: string;
      fee: number;
    },
  ) {
    return this.service.createDoctor(body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch('admin/doctors/:id')
  updateDoctor(@Param('id') id: string, @Body() body: UpdateDoctorDto) {
    return this.service.updateDoctor(id, body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Delete('admin/doctors/:id')
  deleteDoctor(@Param('id') id: string) {
    return this.service.deleteDoctor(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Get('admin/patients')
  findAllPatients() {
    return this.service.findAllPatients();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Delete('admin/patients/:id')
  deletePatient(@Param('id') id: string) {
    return this.service.deletePatient(id);
  }
}
