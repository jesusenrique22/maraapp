import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { AppointmentStatus, Prisma, UserRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import type { AuthUser } from '../common/types/auth-user';
import { PrismaService } from '../prisma/prisma.service';
import { CreateAppointmentDto } from './dto/appointment.dto';

const BOOKING_HOURS = [9, 10, 11, 14, 15, 16, 17];
const ACTIVE_STATUSES: AppointmentStatus[] = [
  AppointmentStatus.PENDING,
  AppointmentStatus.ACCEPTED,
  AppointmentStatus.SCHEDULED,
  AppointmentStatus.IN_PROGRESS,
];

@Injectable()
export class ConsultationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findDoctors() {
    return this.prisma.user.findMany({
      where: {
        role: UserRole.DOCTOR,
        isActive: true,
        doctorProfile: { is: { isActive: true } },
      },
      select: {
        id: true,
        email: true,
        name: true,
        doctorProfile: true,
      },
      orderBy: { name: 'asc' },
    });
  }

  async getDoctorAvailability(doctorProfileId: string, date: string) {
    const profile = await this.prisma.doctorProfile.findUnique({
      where: { id: doctorProfileId },
    });
    if (!profile) throw new NotFoundException('Médico no encontrado');

    const dayStart = new Date(`${date}T00:00:00`);
    const dayEnd = new Date(`${date}T23:59:59`);

    if (Number.isNaN(dayStart.getTime())) {
      throw new BadRequestException('Fecha inválida. Usa formato YYYY-MM-DD');
    }

    const booked = await this.prisma.appointment.findMany({
      where: {
        doctorId: doctorProfileId,
        dateTime: { gte: dayStart, lte: dayEnd },
        status: { in: ACTIVE_STATUSES },
      },
      select: { dateTime: true },
    });

    const bookedHours = new Set(
      booked.map((item) => item.dateTime.getHours()),
    );

    const now = new Date();
    const isToday =
      dayStart.getFullYear() === now.getFullYear() &&
      dayStart.getMonth() === now.getMonth() &&
      dayStart.getDate() === now.getDate();

    const slots = BOOKING_HOURS.map((hour) => {
      const slotDate = new Date(`${date}T${hour.toString().padStart(2, '0')}:00:00`);
      const isPast = isToday && slotDate <= now;
      const isBooked = bookedHours.has(hour);

      return {
        hour,
        label: this.formatHourLabel(hour),
        dateTime: slotDate.toISOString(),
        available: !isPast && !isBooked,
      };
    });

    return { date, slots };
  }

  async createAppointment(patientId: string, dto: CreateAppointmentDto) {
    const profile = await this.prisma.doctorProfile.findUnique({
      where: { id: dto.doctorId },
      include: { user: { select: { isActive: true } } },
    });

    if (!profile || !profile.isActive || !profile.user.isActive) {
      throw new BadRequestException('Médico no disponible');
    }

    const dateTime = new Date(dto.dateTime);
    if (Number.isNaN(dateTime.getTime())) {
      throw new BadRequestException('Fecha u hora inválida');
    }

    this.validateBookingDateTime(dateTime);

    const conflict = await this.prisma.appointment.findFirst({
      where: {
        doctorId: dto.doctorId,
        dateTime,
        status: { in: ACTIVE_STATUSES },
      },
    });

    if (conflict) {
      throw new ConflictException(
        'Ese horario ya está ocupado. Elige otra fecha u hora.',
      );
    }

    const patientConflict = await this.prisma.appointment.findFirst({
      where: {
        patientId,
        dateTime,
        status: { in: ACTIVE_STATUSES },
      },
    });

    if (patientConflict) {
      throw new ConflictException(
        'Ya tienes una cita activa en ese mismo horario.',
      );
    }

    return this.prisma.appointment.create({
      data: {
        patientId,
        doctorId: dto.doctorId,
        dateTime,
        patientNotes: dto.patientNotes?.trim() || null,
        status: AppointmentStatus.PENDING,
      },
      include: this.appointmentIncludeForPatient(),
    });
  }

  async findAppointments(user: AuthUser) {
    if (user.role === UserRole.DOCTOR) {
      const profile = await this.prisma.doctorProfile.findUnique({
        where: { userId: user.id },
      });
      if (!profile) return [];

      return this.prisma.appointment.findMany({
        where: { doctorId: profile.id },
        include: this.appointmentIncludeForDoctor(),
        orderBy: [{ dateTime: 'asc' }],
      });
    }

    return this.prisma.appointment.findMany({
      where: { patientId: user.id },
      include: this.appointmentIncludeForPatient(),
      orderBy: [{ dateTime: 'desc' }],
    });
  }

  async acceptAppointment(appointmentId: string, doctorUserId: string) {
    const appointment = await this.getDoctorAppointment(appointmentId, doctorUserId);

    if (appointment.status !== AppointmentStatus.PENDING) {
      throw new BadRequestException('Solo puedes aceptar citas pendientes');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.ACCEPTED, rejectReason: null },
      include: this.appointmentIncludeForDoctor(),
    });
  }

  async rejectAppointment(
    appointmentId: string,
    doctorUserId: string,
    reason: string,
  ) {
    const appointment = await this.getDoctorAppointment(appointmentId, doctorUserId);

    if (appointment.status !== AppointmentStatus.PENDING) {
      throw new BadRequestException('Solo puedes rechazar citas pendientes');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: {
        status: AppointmentStatus.REJECTED,
        rejectReason: reason.trim(),
      },
      include: this.appointmentIncludeForDoctor(),
    });
  }

  async cancelAppointment(appointmentId: string, patientId: string) {
    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment || appointment.patientId !== patientId) {
      throw new UnauthorizedException('Cita no encontrada');
    }

    if (
      appointment.status !== AppointmentStatus.PENDING &&
      appointment.status !== AppointmentStatus.ACCEPTED &&
      appointment.status !== AppointmentStatus.SCHEDULED
    ) {
      throw new BadRequestException('Esta cita ya no se puede cancelar');
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.CANCELLED },
      include: this.appointmentIncludeForPatient(),
    });
  }

  async startAppointment(appointmentId: string, doctorUserId: string) {
    const appointment = await this.getDoctorAppointment(appointmentId, doctorUserId);

    const canStart =
      appointment.status === AppointmentStatus.ACCEPTED ||
      appointment.status === AppointmentStatus.SCHEDULED;

    if (!canStart) {
      throw new BadRequestException(
        'Debes aceptar la cita antes de iniciar la consulta',
      );
    }

    return this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.IN_PROGRESS },
      include: this.appointmentIncludeForDoctor(),
    });
  }

  async finishAppointment(
    appointmentId: string,
    doctorUserId: string,
    notes: string,
    diagnosis: string,
    prescriptionItems: any[],
  ) {
    const appointment = await this.getDoctorAppointment(appointmentId, doctorUserId);

    if (appointment.status !== AppointmentStatus.IN_PROGRESS) {
      throw new BadRequestException('La consulta no está en progreso');
    }

    const updated = await this.prisma.appointment.update({
      where: { id: appointmentId },
      data: { status: AppointmentStatus.COMPLETED, notes },
    });

    if (diagnosis || (prescriptionItems && prescriptionItems.length > 0)) {
      const rx = await this.prisma.prescription.create({
        data: {
          appointmentId: appointment.id,
          diagnosis: diagnosis || 'Consulta general',
          items: {
            create: prescriptionItems.map((item) => ({
              productId: item.productId || null,
              medicationName: item.medicationName,
              dosage: item.dosage,
              duration: item.duration,
            })),
          },
        },
        include: { items: true },
      });
      return { appointment: updated, prescription: rx };
    }

    return { appointment: updated };
  }

  private async getDoctorAppointment(appointmentId: string, doctorUserId: string) {
    const profile = await this.prisma.doctorProfile.findUnique({
      where: { userId: doctorUserId },
    });
    if (!profile) throw new UnauthorizedException('Perfil de médico no encontrado');

    const appointment = await this.prisma.appointment.findUnique({
      where: { id: appointmentId },
    });

    if (!appointment || appointment.doctorId !== profile.id) {
      throw new UnauthorizedException('Cita no encontrada o no pertenece a este médico');
    }

    return appointment;
  }

  private validateBookingDateTime(dateTime: Date) {
    const now = new Date();
    const maxDate = new Date();
    maxDate.setDate(maxDate.getDate() + 30);

    if (dateTime <= now) {
      throw new BadRequestException('No puedes agendar citas en el pasado');
    }

    if (dateTime > maxDate) {
      throw new BadRequestException('Solo puedes agendar hasta 30 días adelante');
    }

    if (dateTime.getMinutes() !== 0 || dateTime.getSeconds() !== 0) {
      throw new BadRequestException('Selecciona un horario en punto (ej: 10:00)');
    }

    if (!BOOKING_HOURS.includes(dateTime.getHours())) {
      throw new BadRequestException(
        'Horario no disponible. Elige entre 9:00 AM y 5:00 PM',
      );
    }

    const day = dateTime.getDay();
    if (day === 0) {
      throw new BadRequestException('No hay consultas los domingos');
    }
  }

  private formatHourLabel(hour: number) {
    if (hour === 12) return '12:00 PM';
    if (hour > 12) return `${hour - 12}:00 PM`;
    return `${hour}:00 AM`;
  }

  private appointmentIncludeForDoctor(): Prisma.AppointmentInclude {
    return {
      patient: {
        select: { id: true, name: true, email: true },
      },
      prescriptions: {
        include: { items: true },
      },
    };
  }

  private appointmentIncludeForPatient(): Prisma.AppointmentInclude {
    return {
      doctor: {
        include: {
          user: {
            select: { id: true, name: true, email: true },
          },
        },
      },
      prescriptions: {
        include: {
          items: {
            include: {
              product: {
                select: {
                  id: true,
                  name: true,
                  price: true,
                  imageUrl: true,
                },
              },
            },
          },
        },
      },
    };
  }

  // --- ADMINISTRATOR ENDPOINTS ---

  async findAllDoctorsForAdmin() {
    return this.prisma.user.findMany({
      where: { role: UserRole.DOCTOR },
      include: { doctorProfile: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createDoctor(data: {
    email: string;
    name: string;
    specialty: string;
    bio?: string;
    fee: number;
  }) {
    const existing = await this.prisma.user.findUnique({
      where: { email: data.email.toLowerCase() },
    });
    if (existing) throw new ConflictException('El correo ya está registrado');

    const hashedPassword = await bcrypt.hash('Doctor123!', 10);

    return this.prisma.user.create({
      data: {
        email: data.email.toLowerCase(),
        password: hashedPassword,
        name: data.name,
        role: UserRole.DOCTOR,
        doctorProfile: {
          create: {
            specialty: data.specialty,
            bio: data.bio || '',
            consultationFee: data.fee,
          },
        },
      },
      include: { doctorProfile: true },
    });
  }

  async deleteDoctor(userId: string) {
    return this.prisma.user.delete({ where: { id: userId } });
  }

  async updateDoctor(
    userId: string,
    data: {
      name?: string;
      specialty?: string;
      bio?: string;
      fee?: number;
      isActive?: boolean;
    },
  ) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: { doctorProfile: true },
    });

    if (!user || user.role !== UserRole.DOCTOR || !user.doctorProfile) {
      throw new NotFoundException('Médico no encontrado');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(data.name != null && { name: data.name.trim() }),
        ...(data.isActive != null && { isActive: data.isActive }),
      },
    });

    await this.prisma.doctorProfile.update({
      where: { userId },
      data: {
        ...(data.specialty != null && { specialty: data.specialty.trim() }),
        ...(data.bio != null && { bio: data.bio.trim() }),
        ...(data.fee != null && { consultationFee: data.fee }),
        ...(data.isActive != null && { isActive: data.isActive }),
      },
    });

    return this.prisma.user.findUnique({
      where: { id: userId },
      include: { doctorProfile: true },
    });
  }

  async findAllPatients() {
    return this.prisma.user.findMany({
      where: { role: UserRole.CUSTOMER },
      select: {
        id: true,
        email: true,
        name: true,
        isActive: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async deletePatient(userId: string) {
    return this.prisma.user.delete({ where: { id: userId } });
  }
}
