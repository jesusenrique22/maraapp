import {
  IsISO8601,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export class CreateAppointmentDto {
  @IsUUID()
  doctorId: string;

  @IsISO8601()
  dateTime: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  patientNotes?: string;
}

export class RejectAppointmentDto {
  @IsString()
  @MinLength(3)
  @MaxLength(500)
  reason: string;
}
