import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../../home/data/catalog_repository.dart';
import '../../home/domain/models/catalog_models.dart';
import 'appointment_helpers.dart';

enum ConsultationHubRole { doctor, patient }

class ConsultationHubScreen extends ConsumerStatefulWidget {
  const ConsultationHubScreen({
    super.key,
    required this.appointment,
    required this.role,
    this.onUpdated,
  });

  final Map<String, dynamic> appointment;
  final ConsultationHubRole role;
  final VoidCallback? onUpdated;

  static Future<void> open(
    BuildContext context, {
    required Map<String, dynamic> appointment,
    required ConsultationHubRole role,
    VoidCallback? onUpdated,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConsultationHubScreen(
          appointment: appointment,
          role: role,
          onUpdated: onUpdated,
        ),
      ),
    );
  }

  @override
  ConsumerState<ConsultationHubScreen> createState() =>
      _ConsultationHubScreenState();
}

class _ConsultationHubScreenState extends ConsumerState<ConsultationHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  bool _videoLive = false;
  bool _startingVideo = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.appointment['status'] as String? ?? 'ACCEPTED';
    _videoLive = _status == 'IN_PROGRESS';
    final tabCount = widget.role == ConsultationHubRole.doctor ? 3 : 2;
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  String get _peerName {
    if (widget.role == ConsultationHubRole.doctor) {
      final patient = widget.appointment['patient'] as Map<String, dynamic>?;
      return patient?['name'] as String? ?? 'Paciente';
    }
    final doctor = widget.appointment['doctor'] as Map<String, dynamic>?;
    final user = doctor?['user'] as Map<String, dynamic>?;
    return user?['name'] as String? ?? 'Médico';
  }

  String get _peerSubtitle {
    if (widget.role == ConsultationHubRole.doctor) {
      final patient = widget.appointment['patient'] as Map<String, dynamic>?;
      return patient?['email'] as String? ?? '';
    }
    final doctor = widget.appointment['doctor'] as Map<String, dynamic>?;
    return doctor?['specialty'] as String? ?? 'Medicina General';
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará disponible pronto'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startVideoAsDoctor() async {
    if (_videoLive || _startingVideo) return;

    setState(() => _startingVideo = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.postMap(
        '/consultations/appointments/${widget.appointment['id']}/start',
        {},
      );
      if (!mounted) return;
      setState(() {
        _videoLive = true;
        _status = 'IN_PROGRESS';
      });
      widget.onUpdated?.call();
      _tabController.animateTo(1);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: MaraColors.rose),
      );
    } finally {
      if (mounted) setState(() => _startingVideo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _peerName,
              style: const TextStyle(
                color: MaraColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            Text(
              _peerSubtitle,
              style: const TextStyle(
                color: MaraColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AppointmentStatusBadge(status: _status),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E88E5),
          indicatorColor: const Color(0xFF1E88E5),
          tabs: [
            const Tab(icon: Icon(Icons.chat_bubble_outline_rounded, size: 20), text: 'Chat'),
            const Tab(icon: Icon(Icons.videocam_outlined, size: 20), text: 'Videollamada'),
            if (widget.role == ConsultationHubRole.doctor)
              const Tab(icon: Icon(Icons.medical_information_outlined, size: 20), text: 'Receta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ConsultationChatTab(
            controller: _chatController,
            peerName: _peerName,
            isDoctor: widget.role == ConsultationHubRole.doctor,
            onSend: () => _showComingSoon('El chat'),
          ),
          _ConsultationVideoTab(
            peerName: _peerName,
            isDoctor: widget.role == ConsultationHubRole.doctor,
            videoLive: _videoLive,
            starting: _startingVideo,
            onStartVideo: _startVideoAsDoctor,
            onJoinPlaceholder: () => _showComingSoon('Unirse a la videollamada'),
          ),
          if (widget.role == ConsultationHubRole.doctor)
            _DoctorPrescriptionTab(
              appointment: widget.appointment,
              onFinished: () {
                widget.onUpdated?.call();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}

class _ConsultationChatTab extends StatelessWidget {
  const _ConsultationChatTab({
    required this.controller,
    required this.peerName,
    required this.isDoctor,
    required this.onSend,
  });

  final TextEditingController controller;
  final String peerName;
  final bool isDoctor;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final hint = isDoctor
        ? 'Escribe un mensaje a $peerName...'
        : 'Escribe un mensaje a tu médico...';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: MaraColors.green, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chat de consulta (vista previa). Podrás enviar mensajes en una próxima versión.',
                        style: TextStyle(
                          fontSize: 12,
                          color: MaraColors.green,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _ChatBubble(
                text: isDoctor
                    ? 'Hola doctor, tengo una consulta sobre mi cita.'
                    : 'Hola, revisé tu solicitud. Puedes escribirme aquí antes de la videollamada.',
                isMine: false,
                sender: peerName,
              ),
              const SizedBox(height: 10),
              _ChatBubble(
                text: 'Perfecto, gracias. Estoy atento/a.',
                isMine: true,
                sender: 'Tú',
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Los mensajes anteriores son solo de ejemplo',
                  style: TextStyle(
                    fontSize: 11,
                    color: MaraColors.textTertiary.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.paddingOf(context).bottom + 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.attach_file_rounded, color: MaraColors.textSecondary),
                tooltip: 'Adjuntar (próximamente)',
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  padding: const EdgeInsets.all(12),
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.send_rounded, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMine,
    required this.sender,
  });

  final String text;
  final bool isMine;
  final String sender;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              sender,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: MaraColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? const Color(0xFF1E88E5) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                border: isMine ? null : Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: isMine ? Colors.white : MaraColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsultationVideoTab extends StatelessWidget {
  const _ConsultationVideoTab({
    required this.peerName,
    required this.isDoctor,
    required this.videoLive,
    required this.starting,
    required this.onStartVideo,
    required this.onJoinPlaceholder,
  });

  final String peerName;
  final bool isDoctor;
  final bool videoLive;
  final bool starting;
  final VoidCallback onStartVideo;
  final VoidCallback onJoinPlaceholder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: BoxDecoration(
              color: videoLive ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: videoLive ? const Color(0xFF22C55E) : const Color(0xFF334155),
                width: videoLive ? 2 : 1,
              ),
            ),
            child: videoLive
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_rounded, color: Colors.white70, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        isDoctor ? 'Videollamada activa con $peerName' : 'Conectado con $peerName',
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Simulador de llamada (sin funcionalidad real aún)',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isDoctor ? Icons.videocam_off_outlined : Icons.hourglass_empty_rounded,
                        color: Colors.white38,
                        size: 44,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isDoctor
                            ? 'La videollamada no ha comenzado'
                            : 'Esperando que el médico inicie la llamada',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          isDoctor
                              ? 'Puedes chatear primero y luego iniciar la videollamada cuando estés listo.'
                              : 'Mientras tanto puedes usar el chat para escribirle al médico.',
                          style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
          if (isDoctor && !videoLive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: starting ? null : onStartVideo,
                icon: starting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.videocam_rounded),
                label: Text(starting ? 'Iniciando...' : 'Iniciar videollamada'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (!isDoctor && videoLive)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onJoinPlaceholder,
                icon: const Icon(Icons.video_call_rounded),
                label: const Text('Unirse a videollamada'),
                style: FilledButton.styleFrom(
                  backgroundColor: MaraColors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (!isDoctor && !videoLive) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, color: MaraColors.green, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Te avisaremos aquí cuando el médico active la videollamada.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (videoLive) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _VideoControl(icon: Icons.mic_rounded, label: 'Mic'),
                const SizedBox(width: 12),
                _VideoControl(icon: Icons.videocam_rounded, label: 'Cámara'),
                const SizedBox(width: 12),
                _VideoControl(icon: Icons.call_end_rounded, label: 'Colgar', isDanger: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoControl extends StatelessWidget {
  const _VideoControl({
    required this.icon,
    required this.label,
    this.isDanger = false,
  });

  final IconData icon;
  final String label;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: isDanger ? MaraColors.rose : const Color(0xFF334155),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: MaraColors.textSecondary)),
      ],
    );
  }
}

class _DoctorPrescriptionTab extends ConsumerStatefulWidget {
  const _DoctorPrescriptionTab({
    required this.appointment,
    required this.onFinished,
  });

  final Map<String, dynamic> appointment;
  final VoidCallback onFinished;

  @override
  ConsumerState<_DoctorPrescriptionTab> createState() => _DoctorPrescriptionTabState();
}

class _DoctorPrescriptionTabState extends ConsumerState<_DoctorPrescriptionTab> {
  final _observationController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _dosageController = TextEditingController();
  final _durationController = TextEditingController();
  final List<Map<String, dynamic>> _prescribedItems = [];
  Product? _selectedProduct;
  bool _submitting = false;

  @override
  void dispose() {
    _observationController.dispose();
    _diagnosisController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _finishConsultation() async {
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el diagnóstico')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.postMap('/consultations/appointments/${widget.appointment['id']}/finish', {
        'notes': _observationController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'prescriptionItems': _prescribedItems,
      });
      if (!mounted) return;
      widget.onFinished();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consulta finalizada y receta enviada'),
          backgroundColor: MaraColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: MaraColors.rose),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(const ProductQuery()));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ficha clínica y receta',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _diagnosisController,
            decoration: InputDecoration(
              labelText: 'Diagnóstico',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _observationController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notas del médico',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),
          productsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (products) => DropdownButtonFormField<Product>(
              initialValue: _selectedProduct,
              isExpanded: true,
              hint: const Text('Medicamento del catálogo'),
              items: products
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (p) => setState(() => _selectedProduct = p),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dosageController,
                  decoration: InputDecoration(
                    labelText: 'Dosis',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _durationController,
                  decoration: InputDecoration(
                    labelText: 'Duración',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              if (_dosageController.text.trim().isEmpty || _durationController.text.trim().isEmpty) return;
              setState(() {
                _prescribedItems.add({
                  'productId': _selectedProduct?.id,
                  'medicationName': _selectedProduct?.name ?? 'Medicamento',
                  'dosage': _dosageController.text.trim(),
                  'duration': _durationController.text.trim(),
                });
                _dosageController.clear();
                _durationController.clear();
                _selectedProduct = null;
              });
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar a receta'),
          ),
          ..._prescribedItems.map(
            (item) => ListTile(
              title: Text(item['medicationName'] as String),
              subtitle: Text('${item['dosage']} · ${item['duration']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: MaraColors.rose),
                onPressed: () => setState(() => _prescribedItems.remove(item)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitting ? null : _finishConsultation,
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Finalizar consulta', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
