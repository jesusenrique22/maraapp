import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/mara_theme.dart';
import '../patient_telemedicine_screen.dart';

class BookAppointmentSheet extends ConsumerStatefulWidget {
  const BookAppointmentSheet({super.key, required this.doctor});

  final Map<String, dynamic> doctor;

  static Future<bool?> show(BuildContext context, Map<String, dynamic> doctor) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookAppointmentSheet(doctor: doctor),
    );
  }

  @override
  ConsumerState<BookAppointmentSheet> createState() =>
      _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends ConsumerState<BookAppointmentSheet> {
  late DateTime _selectedDate;
  String? _selectedDateTime;
  String? _selectedLabel;
  final _notesController = TextEditingController();
  bool _loadingSlots = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _slots = [];
  String? _slotsError;

  Map<String, dynamic> get _profile =>
      widget.doctor['doctorProfile'] as Map<String, dynamic>;

  String get _doctorName => widget.doctor['name'] as String? ?? 'Médico';

  String get _specialty =>
      _profile['specialty'] as String? ?? 'Medicina General';

  String get _fee => _profile['consultationFee']?.toString() ?? '20.00';

  String get _profileId => _profile['id'] as String;

  @override
  void initState() {
    super.initState();
    _selectedDate = _nextValidDate(DateTime.now());
    _loadSlots();
  }

  DateTime _nextValidDate(DateTime from) {
    var date = DateTime(from.year, from.month, from.day);
    while (date.weekday == DateTime.sunday) {
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  List<DateTime> get _dateOptions {
    final options = <DateTime>[];
    var cursor = _nextValidDate(DateTime.now());
    final last = DateTime.now().add(const Duration(days: 30));

    while (options.length < 14 && !cursor.isAfter(last)) {
      if (cursor.weekday != DateTime.sunday) {
        options.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return options;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateLabel(DateTime date) {
    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _slotsError = null;
      _selectedDateTime = null;
      _selectedLabel = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getMap(
        '/consultations/doctors/$_profileId/availability',
        query: {'date': _formatDateKey(_selectedDate)},
      );
      final slots = (response['slots'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _slotsError = error.toString();
        _loadingSlots = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Selecciona el día de tu cita',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );

    if (picked == null) return;

    if (picked.weekday == DateTime.sunday) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay consultas los domingos'),
          backgroundColor: MaraColors.rose,
        ),
      );
      return;
    }

    setState(() => _selectedDate = picked);
    await _loadSlots();
  }

  Future<void> _confirmBooking() async {
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un horario disponible')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final api = ref.read(apiClientProvider);
      await api.postMap('/consultations/appointments', {
        'doctorId': _profileId,
        'dateTime': _selectedDateTime,
        if (_notesController.text.trim().isNotEmpty)
          'patientNotes': _notesController.text.trim(),
      });

      ref.invalidate(patientAppointmentsProvider);

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: MaraColors.rose),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo agendar: $error'),
          backgroundColor: MaraColors.rose,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE3F2FD),
                    child: Text(
                      _doctorName.isNotEmpty ? _doctorName[0] : 'D',
                      style: const TextStyle(
                        color: MaraColors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                        Text(
                          _specialty,
                          style: const TextStyle(
                            color: MaraColors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$$_fee',
                      style: const TextStyle(
                        color: MaraColors.green,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Agendar consulta virtual',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: MaraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'El médico debe aceptar tu solicitud antes de confirmar la cita.',
                style: TextStyle(color: MaraColors.textSecondary, height: 1.4, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Reglas de agendamiento',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: MaraColors.green,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '• Lun–Sáb, 9 AM – 5 PM (sin domingos)\n'
                      '• Un horario por médico (no doble reserva)\n'
                      '• Máximo 30 días de anticipación\n'
                      '• Estado inicial: Pendiente de aprobación',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: MaraColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(icon: Icons.calendar_month_rounded, label: 'Elige el día'),
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _dateOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final date = _dateOptions[index];
                    final selected = _isSameDay(date, _selectedDate);
                    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedDate = date);
                        _loadSlots();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 64,
                        decoration: BoxDecoration(
                          color: selected
                              ? MaraColors.green
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? MaraColors.green
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              weekdays[date.weekday - 1],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white70
                                    : MaraColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: selected
                                    ? Colors.white
                                    : MaraColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, color: MaraColors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _formatDateLabel(_selectedDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: MaraColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: MaraColors.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(icon: Icons.schedule_rounded, label: 'Horario disponible'),
              const SizedBox(height: 10),
              if (_loadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: MaraColors.green),
                  ),
                )
              else if (_slotsError != null)
                Text(_slotsError!, style: const TextStyle(color: MaraColors.rose))
              else if (_slots.where((s) => s['available'] == true).isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: MaraColors.amberLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'No hay horarios libres este día. Prueba otra fecha.',
                    style: TextStyle(color: MaraColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _slots.map((slot) {
                        final available = slot['available'] == true;
                        final label = slot['label'] as String? ?? '';
                        final dateTime = slot['dateTime'] as String?;
                        final selected = _selectedDateTime == dateTime;
                        final isBooked = slot['available'] == false &&
                            !(DateTime.tryParse(dateTime ?? '')?.isBefore(DateTime.now()) ?? false);

                        return FilterChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: available
                              ? (value) {
                                  setState(() {
                                    _selectedDateTime = dateTime;
                                    _selectedLabel = label;
                                  });
                                }
                              : null,
                          showCheckmark: false,
                          selectedColor: MaraColors.green,
                          backgroundColor: available
                              ? const Color(0xFFF8FAFC)
                              : isBooked
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: selected
                                ? Colors.white
                                : available
                                    ? MaraColors.textPrimary
                                    : MaraColors.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                          side: BorderSide(
                            color: selected
                                ? MaraColors.green
                                : isBooked
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFE2E8F0),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        _SlotLegend(color: Color(0xFFF8FAFC), border: Color(0xFFE2E8F0), label: 'Libre'),
                        SizedBox(width: 12),
                        _SlotLegend(color: Color(0xFFFEE2E2), border: Color(0xFFFECACA), label: 'Ocupado'),
                        SizedBox(width: 12),
                        _SlotLegend(color: Color(0xFFF1F5F9), border: Color(0xFFE2E8F0), label: 'Pasado'),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              _SectionLabel(icon: Icons.notes_rounded, label: 'Motivo de consulta (opcional)'),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ej: Dolor de cabeza desde ayer, fiebre leve...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (_selectedLabel != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Resumen: $_selectedLabel · ${_formatDateLabel(_selectedDate)} · \$$_fee',
                    style: const TextStyle(
                      color: MaraColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : _confirmBooking,
                  style: FilledButton.styleFrom(
                    backgroundColor: MaraColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Solicitar cita',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: MaraColors.green),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: MaraColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _SlotLegend extends StatelessWidget {
  const _SlotLegend({
    required this.color,
    required this.border,
    required this.label,
  });

  final Color color;
  final Color border;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: MaraColors.textSecondary),
        ),
      ],
    );
  }
}
