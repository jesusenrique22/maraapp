import 'package:flutter/material.dart';

class AppointmentStatusInfo {
  const AppointmentStatusInfo({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  static AppointmentStatusInfo from(String? status) {
    switch (status) {
      case 'PENDING':
        return const AppointmentStatusInfo(
          label: 'Pendiente',
          background: Color(0xFFFFF7ED),
          foreground: Color(0xFFEA580C),
        );
      case 'ACCEPTED':
      case 'SCHEDULED':
        return const AppointmentStatusInfo(
          label: 'Confirmada',
          background: Color(0xFFE0F7FA),
          foreground: Color(0xFF006064),
        );
      case 'REJECTED':
        return const AppointmentStatusInfo(
          label: 'Rechazada',
          background: Color(0xFFFFEBEE),
          foreground: Color(0xFFC62828),
        );
      case 'IN_PROGRESS':
        return const AppointmentStatusInfo(
          label: 'En llamada',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
      case 'COMPLETED':
        return const AppointmentStatusInfo(
          label: 'Completada',
          background: Color(0xFFE8F5E9),
          foreground: Color(0xFF2E7D32),
        );
      case 'CANCELLED':
        return const AppointmentStatusInfo(
          label: 'Cancelada',
          background: Color(0xFFECEFF1),
          foreground: Color(0xFF37474F),
        );
      default:
        return const AppointmentStatusInfo(
          label: 'Desconocido',
          background: Color(0xFFECEFF1),
          foreground: Color(0xFF37474F),
        );
    }
  }
}

class AppointmentStatusBadge extends StatelessWidget {
  const AppointmentStatusBadge({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final info = AppointmentStatusInfo.from(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        info.label,
        style: TextStyle(
          color: info.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String formatAppointmentDateTime(String? iso) {
  if (iso == null) return 'Sin fecha';
  final date = DateTime.parse(iso).toLocal();
  const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  const months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];
  final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');
  return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}, $hour:$minute $suffix';
}
