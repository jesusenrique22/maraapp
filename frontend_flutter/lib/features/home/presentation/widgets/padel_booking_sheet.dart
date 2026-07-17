import 'package:flutter/material.dart';

import '../../../../core/theme/mara_theme.dart';

/// Reserva de pádel a pantalla completa.
class PadelBookingSheet {
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => const PadelBookingScreen(),
      ),
    );
  }
}

class PadelBookingScreen extends StatefulWidget {
  const PadelBookingScreen({super.key});

  @override
  State<PadelBookingScreen> createState() => _PadelBookingScreenState();
}

class _PadelBookingScreenState extends State<PadelBookingScreen> {
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: MaraColors.textPrimary),
        ),
        title: const Text(
          'Reservar pádel',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: MaraColors.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _confirmed
            ? _SuccessView(
                court: _courts[_courtIndex],
                dateLabel: _dateLabel,
                slot: _slots[_slotIndex],
                onClose: () => Navigator.pop(context),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF0284C7),
                                  Color(0xFF0369A1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.sports_tennis_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'MaraPadel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 20,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Elige cancha, día y horario para tu partido',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          const _SectionLabel('Cancha'),
                          const SizedBox(height: 12),
                          ...List.generate(_courts.length, (i) {
                            final selected = _courtIndex == i;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: InkWell(
                                onTap: () => setState(() => _courtIndex = i),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? const Color(0xFFE0F2FE)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: selected
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFFE2E8F0),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_off,
                                        color: selected
                                            ? const Color(0xFF0284C7)
                                            : MaraColors.textTertiary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _courts[i],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: selected
                                                ? const Color(0xFF0284C7)
                                                : MaraColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 18),
                          const _SectionLabel('Día'),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    color: Color(0xFF0284C7),
                                    size: 26,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _dateLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: MaraColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Cambiar',
                                    style: TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel('Horario'),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _slots.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 2.8,
                            ),
                            itemBuilder: (context, i) {
                              final selected = _slotIndex == i;
                              return InkWell(
                                onTap: () => setState(() => _slotIndex = i),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? MaraColors.green
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? MaraColors.green
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    _slots[i],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: selected
                                          ? Colors.white
                                          : MaraColors.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _submitting ? null : _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar reserva',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
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
        fontWeight: FontWeight.w900,
        fontSize: 15,
        color: MaraColors.textPrimary,
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
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
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: MaraColors.greenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: MaraColors.greenDark,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Reserva lista!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: MaraColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$court\n$dateLabel · $slot',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MaraColors.textSecondary,
              fontSize: 16,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: onClose,
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Listo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
