import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../admin/providers/admin_providers.dart';
import '../../home/domain/models/catalog_models.dart';
import '../../home/providers/cart_provider.dart';
import 'widgets/book_appointment_sheet.dart';
import '../../consultations/presentation/appointment_helpers.dart';
import '../../consultations/presentation/consultation_hub_screen.dart';

final patientDoctorsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getList('/consultations/doctors');
});

final patientAppointmentsProvider = FutureProvider<List<dynamic>>((ref) async {
  final auth = ref.watch(adminAuthProvider);
  if (!auth.isAuthenticated) return [];

  final api = ref.watch(apiClientProvider);
  return api.getList('/consultations/appointments');
});

class PatientTelemedicineScreen extends ConsumerStatefulWidget {
  const PatientTelemedicineScreen({super.key});

  @override
  ConsumerState<PatientTelemedicineScreen> createState() => _PatientTelemedicineScreenState();
}

class _PatientTelemedicineScreenState extends ConsumerState<PatientTelemedicineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Product _parseProduct(Map<String, dynamic> pJson) {
    return Product(
      id: pJson['id'] as String,
      sku: pJson['sku'] as String? ?? 'RX-MED',
      name: pJson['name'] as String,
      price: (pJson['price'] as num?)?.toDouble() ?? 5.0,
      finalPrice: (pJson['finalPrice'] as num?)?.toDouble() ?? (pJson['price'] as num?)?.toDouble() ?? 5.0,
      stock: (pJson['stock'] as num?)?.toInt() ?? 10,
      inStock: pJson['inStock'] as bool? ?? true,
      imageUrl: pJson['imageUrl'] as String?,
      category: const ProductCategory(
        id: 'farmacia-cat',
        name: 'Farmacia',
        slug: 'farmacia',
      ),
      description: pJson['description'] as String?,
    );
  }

  Future<void> _bookAppointment(Map<String, dynamic> doctor) async {
    final booked = await BookAppointmentSheet.show(context, doctor);
    if (booked != true || !mounted) return;

    _tabController.animateTo(1);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Solicitud enviada. El médico debe aceptar tu cita.',
        ),
        backgroundColor: MaraColors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openConsultationHub(Map<String, dynamic> appointment) {
    ConsultationHubScreen.open(
      context,
      appointment: appointment,
      role: ConsultationHubRole.patient,
      onUpdated: () => ref.invalidate(patientAppointmentsProvider),
    );
  }

  Map<String, dynamic>? _asDoctorMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<dynamic>>>(
      patientDoctorsProvider,
      (previous, next) {
        next.whenData((doctors) {
          if (!mounted) return;
          final bookDoctorId =
              GoRouterState.of(context).uri.queryParameters['bookDoctorId'];
          if (bookDoctorId == null || bookDoctorId.isEmpty) return;

          Map<String, dynamic>? match;
          for (final raw in doctors) {
            final doc = _asDoctorMap(raw);
            if (doc == null) continue;
            final profile = _asDoctorMap(doc['doctorProfile']);
            if (doc['id'] == bookDoctorId || profile?['id'] == bookDoctorId) {
              match = doc;
              break;
            }
          }
          if (match == null) return;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            context.go('/medic-plus');
            _bookAppointment(match!);
          });
        });
      },
    );

    final doctorsAsync = ref.watch(patientDoctorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: MaraColors.greenLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: MaraColors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Medic Express',
              style: TextStyle(
                color: MaraColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined, color: MaraColors.navyMid),
            tooltip: 'Ir a la tienda',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: MaraColors.rose),
            onPressed: () async {
              await ref.read(adminAuthProvider.notifier).logout();
              if (context.mounted) context.go('/home');
            },
            tooltip: 'Cerrar sesión',
          ),
          const SizedBox(width: 8),
        ],
        // TabBar nativo (sin PreferredSize/iconos): evita "RenderBox was not laid out"
        bottom: TabBar(
          controller: _tabController,
          labelColor: MaraColors.green,
          unselectedLabelColor: MaraColors.textSecondary,
          indicatorColor: MaraColors.green,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Reservar'),
            Tab(text: 'Mis Citas'),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return IndexedStack(
            index: _tabController.index,
            children: [
              _ReservarDoctorsTab(
                searchController: _searchController,
                filterQuery: _filterQuery,
                doctorsAsync: doctorsAsync,
                onFilterChanged: (val) => setState(() => _filterQuery = val.trim()),
                onClearFilter: () {
                  _searchController.clear();
                  setState(() => _filterQuery = '');
                },
                onRetry: () => ref.invalidate(patientDoctorsProvider),
                onBook: _bookAppointment,
              ),
              _PatientAppointmentsTab(
                onOpenHub: _openConsultationHub,
                parseProduct: _parseProduct,
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: OutlinedButton.icon(
            onPressed: () => context.go('/home'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            icon: const Icon(Icons.storefront_outlined, color: MaraColors.textPrimary),
            label: const Text(
              'Volver a la Tienda',
              style: TextStyle(
                color: MaraColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReservarDoctorsTab extends StatelessWidget {
  const _ReservarDoctorsTab({
    required this.searchController,
    required this.filterQuery,
    required this.doctorsAsync,
    required this.onFilterChanged,
    required this.onClearFilter,
    required this.onRetry,
    required this.onBook,
  });

  final TextEditingController searchController;
  final String filterQuery;
  final AsyncValue<List<dynamic>> doctorsAsync;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onClearFilter;
  final VoidCallback onRetry;
  final Future<void> Function(Map<String, dynamic> doctor) onBook;

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Buscar médicos por especialidad o nombre...',
              hintStyle: const TextStyle(
                fontSize: 13,
                color: MaraColors.textSecondary,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: MaraColors.green,
                size: 20,
              ),
              suffixIcon: filterQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: onClearFilter,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: MaraColors.green, width: 1.2),
              ),
            ),
            onChanged: onFilterChanged,
          ),
        ),
        Expanded(
          child: doctorsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: MaraColors.green),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 40, color: MaraColors.rose),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar los médicos',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$err',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MaraColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: MaraColors.green,
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            data: (doctors) {
              final validDoctors = <Map<String, dynamic>>[];
              for (final raw in doctors) {
                final doc = _asMap(raw);
                if (doc == null) continue;
                final profile = _asMap(doc['doctorProfile']);
                if (profile == null) continue;

                final name = (doc['name'] ?? '').toString().toLowerCase();
                final specialty =
                    (profile['specialty'] ?? '').toString().toLowerCase();
                final query = filterQuery.toLowerCase();
                if (query.isEmpty ||
                    name.contains(query) ||
                    specialty.contains(query)) {
                  validDoctors.add(doc);
                }
              }

              if (validDoctors.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Text(
                      filterQuery.isNotEmpty
                          ? 'No se encontraron médicos para "$filterQuery"'
                          : 'No hay médicos disponibles por el momento.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: MaraColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: validDoctors.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final doc = validDoctors[index];
                  final profile = _asMap(doc['doctorProfile'])!;
                  final specialty =
                      profile['specialty'] as String? ?? 'Medicina General';
                  final bio = profile['bio'] as String? ??
                      'Médico profesional disponible para tele-consulta.';
                  final fee =
                      profile['consultationFee']?.toString() ?? '20.00';
                  final doctorName = doc['name'] as String? ?? 'Médico';
                  final initial =
                      doctorName.isNotEmpty ? doctorName[0].toUpperCase() : 'D';

                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => onBook(doc),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundColor: MaraColors.greenLight,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: MaraColors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: MaraColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        specialty,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: MaraColors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '\$$fee',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: MaraColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: MaraColors.textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => onBook(doc),
                                style: FilledButton.styleFrom(
                                  backgroundColor: MaraColors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Reservar cita',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PatientAppointmentsTab extends ConsumerWidget {
  const _PatientAppointmentsTab({
    required this.onOpenHub,
    required this.parseProduct,
  });

  final void Function(Map<String, dynamic> appointment) onOpenHub;
  final Product Function(Map<String, dynamic> json) parseProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(patientAppointmentsProvider);

    return appointmentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MaraColors.green),
      ),
      error: (err, _) => Center(child: Text('Error al cargar historial: $err')),
      data: (appointments) {
        if (appointments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_rounded, size: 48, color: MaraColors.textTertiary),
                  SizedBox(height: 12),
                  Text(
                    'No tienes citas programadas ni recetas registradas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MaraColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(patientAppointmentsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final apt = appointments[index] as Map<String, dynamic>;
              final status = apt['status'] as String? ?? 'SCHEDULED';
              final canOpenHub = status == 'ACCEPTED' ||
                  status == 'SCHEDULED' ||
                  status == 'IN_PROGRESS';

              final doctor = apt['doctor'] as Map<String, dynamic>?;
              final doctorUser = doctor?['user'] as Map<String, dynamic>?;
              final docName = doctorUser?['name'] as String? ?? 'Médico Asignado';
              final specialty =
                  doctor?['specialty'] as String? ?? 'Medicina General';

              final prescriptions = apt['prescriptions'] as List<dynamic>? ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: status == 'IN_PROGRESS'
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFF1F5F9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: status == 'IN_PROGRESS'
                          ? const Color(0xFF22C55E).withValues(alpha: 0.08)
                          : const Color(0xFF0F172A).withValues(alpha: 0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: status == 'IN_PROGRESS'
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              status == 'IN_PROGRESS'
                                  ? Icons.videocam_rounded
                                  : Icons.calendar_today_rounded,
                              color: status == 'IN_PROGRESS'
                                  ? MaraColors.green
                                  : MaraColors.textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  docName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.5,
                                    color: MaraColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  specialty,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: MaraColors.green,
                                    fontWeight: FontWeight.w900,
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
                          color: MaraColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (apt['patientNotes'] != null &&
                          apt['patientNotes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Tu motivo: ${apt['patientNotes']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: MaraColors.textSecondary,
                          ),
                        ),
                      ],
                      if (status == 'REJECTED' &&
                          apt['rejectReason'] != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: MaraColors.roseLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Motivo del rechazo: ${apt['rejectReason']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MaraColors.rose,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      if (status == 'PENDING') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFFEA580C)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Esperando que el médico acepte tu solicitud.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEA580C),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (status == 'ACCEPTED' || status == 'SCHEDULED') ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: MaraColors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Cita confirmada. Entra a la sala para chatear; la videollamada la inicia el médico.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      if (canOpenHub) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: () => onOpenHub(apt),
                            style: FilledButton.styleFrom(
                              backgroundColor: status == 'IN_PROGRESS'
                                  ? MaraColors.green
                                  : MaraColors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: Icon(
                              status == 'IN_PROGRESS'
                                  ? Icons.video_call_rounded
                                  : Icons.meeting_room_outlined,
                            ),
                            label: Text(
                              status == 'IN_PROGRESS'
                                  ? 'Entrar a la sala (videollamada activa)'
                                  : 'Abrir sala de consulta',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (prescriptions.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(
                              Icons.assignment_turned_in_rounded,
                              size: 14,
                              color: MaraColors.green,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Receta Digital Emitida:',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                color: MaraColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...prescriptions.map((rx) {
                          final rxMap = rx as Map<String, dynamic>;
                          final items = rxMap['items'] as List<dynamic>? ?? [];
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Diagnóstico: ${rxMap['diagnosis'] ?? 'Consulta general'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: MaraColors.green,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...items.map((item) {
                                  final itemMap = item as Map<String, dynamic>;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• ${itemMap['medicationName']}: ${itemMap['dosage']} (${itemMap['duration']})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: MaraColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  height: 42,
                                  child: FilledButton.icon(
                                    onPressed: () {
                                      var count = 0;
                                      for (final item in items) {
                                        final itemMap =
                                            item as Map<String, dynamic>;
                                        if (itemMap['product'] != null) {
                                          ref
                                              .read(cartProvider.notifier)
                                              .addProduct(
                                                parseProduct(
                                                  itemMap['product']
                                                      as Map<String, dynamic>,
                                                ),
                                              );
                                          count++;
                                        }
                                      }
                                      if (count > 0) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              '¡Se agregaron $count medicamentos al carrito!',
                                            ),
                                            backgroundColor: MaraColors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Este medicamento recetado no está enlazado al inventario de farmacia.',
                                            ),
                                            backgroundColor: MaraColors.rose,
                                          ),
                                        );
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: MaraColors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.shopping_cart_checkout_rounded,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Comprar todo de la Receta',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else if (apt['notes'] != null &&
                          apt['notes'].toString().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Indicaciones del médico:\n${apt['notes']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: MaraColors.textSecondary,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (status == 'PENDING' ||
                          status == 'ACCEPTED' ||
                          status == 'SCHEDULED') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final api = ref.read(apiClientProvider);
                                await api.postMap(
                                  '/consultations/appointments/${apt['id']}/cancel',
                                  {},
                                );
                                ref.invalidate(patientAppointmentsProvider);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Cita cancelada'),
                                    backgroundColor: MaraColors.green,
                                  ),
                                );
                              } on ApiException catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error.message),
                                    backgroundColor: MaraColors.rose,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.cancel_outlined, size: 18),
                            label: const Text('Cancelar cita'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
