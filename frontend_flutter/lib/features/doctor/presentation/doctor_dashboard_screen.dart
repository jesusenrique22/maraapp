import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../admin/providers/admin_providers.dart';

import '../../consultations/presentation/appointment_helpers.dart';
import '../../consultations/presentation/consultation_hub_screen.dart';

final doctorAppointmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(adminAuthProvider);
  final api = ref.watch(apiClientProvider);
  return api.getList('/consultations/appointments');
});

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAppointments(
    List<dynamic> appointments,
    String filter,
  ) {
    final list = appointments.cast<Map<String, dynamic>>();
    switch (filter) {
      case 'pending':
        return list.where((a) => a['status'] == 'PENDING').toList();
      case 'active':
        return list.where((a) {
          final status = a['status'];
          return status == 'ACCEPTED' ||
              status == 'SCHEDULED' ||
              status == 'IN_PROGRESS';
        }).toList();
      default:
        return list.where((a) {
          final status = a['status'];
          return status == 'COMPLETED' ||
              status == 'REJECTED' ||
              status == 'CANCELLED';
        }).toList();
    }
  }

  Future<void> _acceptAppointment(Map<String, dynamic> appointment) async {
    final patient = appointment['patient'] as Map<String, dynamic>? ?? {};
    final patName = patient['name'] as String? ?? 'Paciente';
    final when = formatAppointmentDateTime(appointment['dateTime'] as String?);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar cita', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          '¿Aceptas la cita de $patName para el $when?\n\n'
          'El paciente podrá conectarse cuando inicies la consulta.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: MaraColors.green),
            child: const Text('Aceptar cita'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.postMap('/consultations/appointments/${appointment['id']}/accept', {});
      ref.invalidate(doctorAppointmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cita aceptada. Abre la sala para chatear o iniciar la videollamada.'),
          backgroundColor: MaraColors.green,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: MaraColors.rose),
      );
    }
  }

  Future<void> _rejectAppointment(Map<String, dynamic> appointment) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar cita', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Indica el motivo para el paciente:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: No tengo disponibilidad en ese horario',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: MaraColors.rose),
            child: const Text('Rechazar cita'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.trim().length < 3) {
      if (confirmed == true && reasonController.text.trim().length < 3 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Escribe un motivo de al menos 3 caracteres'),
            backgroundColor: MaraColors.rose,
          ),
        );
      }
      reasonController.dispose();
      return;
    }

    try {
      final api = ref.read(apiClientProvider);
      await api.postMap('/consultations/appointments/${appointment['id']}/reject', {
        'reason': reasonController.text.trim(),
      });
      ref.invalidate(doctorAppointmentsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cita rechazada'), backgroundColor: MaraColors.amber),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: MaraColors.rose),
      );
    } finally {
      reasonController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(adminAuthProvider).session?.user;
    final appointmentsAsync = ref.watch(doctorAppointmentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: const [
            Icon(Icons.medical_services_outlined, color: Color(0xFF1E88E5)),
            SizedBox(width: 8),
            Text(
              'Panel Médico Farma Express',
              style: TextStyle(
                color: MaraColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1E88E5)),
            onPressed: () => ref.invalidate(doctorAppointmentsProvider),
            tooltip: 'Actualizar agenda',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: MaraColors.rose),
            onPressed: () {
              ref.read(adminAuthProvider.notifier).logout();
              context.go('/medic-plus/login');
            },
            tooltip: 'Cerrar Sesión',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: appointmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
        error: (err, _) => Center(child: Text('Error al cargar agenda: $err')),
        data: (appointments) {
          final pending = _filterAppointments(appointments, 'pending');
          final active = _filterAppointments(appointments, 'active');
          final history = _filterAppointments(appointments, 'history');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blue.shade50,
                              child: const Icon(Icons.person_rounded, color: Color(0xFF1E88E5), size: 30),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.name ?? 'Médico Farma Express',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Text(
                                    'Gestiona solicitudes y consultas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: MaraColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _DoctorStatChip(
                              label: 'Pendientes',
                              value: '${pending.length}',
                              color: const Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 8),
                            _DoctorStatChip(
                              label: 'Confirmadas',
                              value: '${active.length}',
                              color: const Color(0xFF1E88E5),
                            ),
                            const SizedBox(width: 8),
                            _DoctorStatChip(
                              label: 'Historial',
                              value: '${history.length}',
                              color: MaraColors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFF1E88E5),
                indicatorColor: const Color(0xFF1E88E5),
                tabs: [
                  Tab(text: 'Pendientes (${pending.length})'),
                  Tab(text: 'Confirmadas (${active.length})'),
                  const Tab(text: 'Historial'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _DoctorAppointmentList(
                      appointments: pending,
                      emptyMessage: 'No hay solicitudes pendientes.',
                      onAccept: _acceptAppointment,
                      onReject: _rejectAppointment,
                    ),
                    _DoctorAppointmentList(
                      appointments: active,
                      emptyMessage: 'No tienes citas confirmadas.',
                      onOpenHub: _openConsultationHub,
                    ),
                    _DoctorAppointmentList(
                      appointments: history,
                      emptyMessage: 'Aún no hay historial de consultas.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openConsultationHub(Map<String, dynamic> appointment) {
    ConsultationHubScreen.open(
      context,
      appointment: appointment,
      role: ConsultationHubRole.doctor,
      onUpdated: () => ref.invalidate(doctorAppointmentsProvider),
    );
  }
}

class _DoctorStatChip extends StatelessWidget {
  const _DoctorStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: MaraColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorAppointmentList extends StatelessWidget {
  const _DoctorAppointmentList({
    required this.appointments,
    required this.emptyMessage,
    this.onAccept,
    this.onReject,
    this.onOpenHub,
  });

  final List<Map<String, dynamic>> appointments;
  final String emptyMessage;
  final Future<void> Function(Map<String, dynamic>)? onAccept;
  final Future<void> Function(Map<String, dynamic>)? onReject;
  final void Function(Map<String, dynamic>)? onOpenHub;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            emptyMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MaraColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final apt = appointments[index];
        final patient = apt['patient'] as Map<String, dynamic>? ?? {};
        final patName = patient['name'] as String? ?? 'Paciente';
        final patEmail = patient['email'] as String? ?? '';
        final status = apt['status'] as String?;
        final isPending = status == 'PENDING';
        final canOpenHub = status == 'ACCEPTED' ||
            status == 'SCHEDULED' ||
            status == 'IN_PROGRESS';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.person_outline_rounded, color: MaraColors.navyMid),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patName,
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                          ),
                          Text(
                            patEmail,
                            style: const TextStyle(
                              fontSize: 11,
                              color: MaraColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppointmentStatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatAppointmentDateTime(apt['dateTime'] as String?),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                if (apt['patientNotes'] != null &&
                    apt['patientNotes'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Motivo del paciente',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          apt['patientNotes'].toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: MaraColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (status == 'REJECTED' && apt['rejectReason'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Rechazada: ${apt['rejectReason']}',
                    style: const TextStyle(fontSize: 12, color: MaraColors.rose),
                  ),
                ],
                if (isPending && onAccept != null && onReject != null) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Revisa la solicitud y confirma o rechaza con motivo.',
                    style: TextStyle(
                      fontSize: 11,
                      color: MaraColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onReject!(apt),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rechazar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MaraColors.rose,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => onAccept!(apt),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Aceptar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: MaraColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (canOpenHub && onOpenHub != null) ...[
                  const Divider(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => onOpenHub!(apt),
                      icon: const Icon(Icons.meeting_room_outlined, size: 18),
                      label: Text(
                        status == 'IN_PROGRESS'
                            ? 'Continuar sala de consulta'
                            : 'Abrir sala de consulta',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E88E5),
                        side: const BorderSide(color: Color(0xFF1E88E5)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chat, videollamada y receta dentro de la sala.',
                    style: TextStyle(fontSize: 11, color: MaraColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
