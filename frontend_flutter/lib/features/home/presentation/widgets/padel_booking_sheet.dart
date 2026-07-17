import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';

/// Flujo de reserva de cancha de pádel.
class PadelBookingSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _PadelBookingSheetBody(),
    );
  }
}

class _PadelBookingSheetBody extends StatefulWidget {
  const _PadelBookingSheetBody();

  @override
  State<_PadelBookingSheetBody> createState() => _PadelBookingSheetBodyState();
}

class _PadelBookingSheetBodyState extends State<_PadelBookingSheetBody> {
  static const _courts = [
    'Cancha 1 · Cubierta',
    'Cancha 2 · Exterior',
    'Cancha 3 · Premium',
  ];

  static const _slots = [
    '08:00 – 09:30',
    '09:30 – 11:00',
    '11:00 – 12:30',
    '14:00 – 15:30',
    '15:30 – 17:00',
    '17:00 – 18:30',
    '18:30 – 20:00',
    '20:00 – 21:30',
  ];

  static const _weekdays = [
    'Lun',
    'Mar',
    'Mié',
    'Jue',
    'Vie',
    'Sáb',
    'Dom',
  ];

  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  int _courtIndex = 0;
  int _slotIndex = 2;
  late DateTime _date;
  bool _submitting = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  String get _dateLabel {
    final weekday = _weekdays[_date.weekday - 1];
    final month = _months[_date.month - 1];
    return '$weekday ${_date.day} $month';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      helpText: 'Elige el día',
      cancelText: 'Cancelar',
      confirmText: 'Listo',
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _confirmed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottom),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sports_tennis_rounded,
                  color: Color(0xFF0284C7),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservar pádel',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: MaraColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Elige cancha, día y horario',
                      style: TextStyle(
                        fontSize: 12,
                        color: MaraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_confirmed)
            _SuccessBlock(
              court: _courts[_courtIndex],
              dateLabel: _dateLabel,
              slot: _slots[_slotIndex],
              onClose: () => Navigator.pop(context),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionLabel('Cancha'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_courts.length, (i) {
                        final selected = _courtIndex == i;
                        return ChoiceChip(
                          label: Text(_courts[i]),
                          selected: selected,
                          onSelected: (_) => setState(() => _courtIndex = i),
                          selectedColor: const Color(0xFF0284C7),
                          labelStyle: TextStyle(
                            color:
                                selected ? Colors.white : MaraColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: selected
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Día'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _dateLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: MaraColors.textPrimary,
                                ),
                              ),
                            ),
                            const Text(
                              'Cambiar',
                              style: TextStyle(
                                color: Color(0xFF0284C7),
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionLabel('Horario'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(_slots.length, (i) {
                        final selected = _slotIndex == i;
                        return ChoiceChip(
                          label: Text(_slots[i]),
                          selected: selected,
                          onSelected: (_) => setState(() => _slotIndex = i),
                          selectedColor: MaraColors.green,
                          labelStyle: TextStyle(
                            color:
                                selected ? Colors.white : MaraColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFFF8FAFC),
                          side: BorderSide(
                            color: selected
                                ? MaraColors.green
                                : const Color(0xFFE2E8F0),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: _submitting ? null : _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar reserva',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: MaraColors.textPrimary,
      ),
    );
  }
}

class _SuccessBlock extends StatelessWidget {
  const _SuccessBlock({
    required this.court,
    required this.dateLabel,
    required this.slot,
    required this.onClose,
  });

  final String court;
  final String dateLabel;
  final String slot;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: MaraColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: MaraColors.greenDark,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '¡Reserva lista!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$court\n$dateLabel · $slot',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MaraColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Listo',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
