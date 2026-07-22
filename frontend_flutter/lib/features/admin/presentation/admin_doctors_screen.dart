import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/mara_theme.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_shell.dart';
import 'widgets/admin_ui_widgets.dart';

class AdminDoctorsScreen extends ConsumerStatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  ConsumerState<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends ConsumerState<AdminDoctorsScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _feeController = TextEditingController(text: '20.00');
  final _bioController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _specialtyController.dispose();
    _feeController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _showDoctorDialog({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;
    final profile = existing?['doctorProfile'] as Map<String, dynamic>?;

    _emailController.text = existing?['email'] as String? ?? '';
    _nameController.text = existing?['name'] as String? ?? '';
    _specialtyController.text = profile?['specialty'] as String? ?? '';
    _feeController.text = profile?['consultationFee']?.toString() ?? '20.00';
    _bioController.text = profile?['bio'] as String? ?? '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar médico' : 'Registrar médico'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isEdit)
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Correo',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  if (!isEdit) const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _specialtyController,
                    decoration: const InputDecoration(labelText: 'Especialidad', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _feeController,
                    decoration: const InputDecoration(labelText: 'Tarifa (\$)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _bioController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Biografía', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      if (_nameController.text.trim().isEmpty ||
                          _specialtyController.text.trim().isEmpty ||
                          _feeController.text.trim().isEmpty) {
                        return;
                      }

                      setDialogState(() => _saving = true);
                      try {
                        final repo = ref.read(adminRepositoryProvider);
                        final fee = double.parse(_feeController.text.trim());

                        if (isEdit) {
                          await repo.updateAdminDoctor(
                            existing['id'] as String,
                            name: _nameController.text.trim(),
                            specialty: _specialtyController.text.trim(),
                            fee: fee,
                            bio: _bioController.text.trim(),
                          );
                        } else {
                          if (_emailController.text.trim().isEmpty) return;
                          await repo.createAdminDoctor(
                            email: _emailController.text.trim(),
                            name: _nameController.text.trim(),
                            specialty: _specialtyController.text.trim(),
                            fee: fee,
                            bio: _bioController.text.trim(),
                          );
                        }

                        ref.invalidate(adminDoctorsProvider);
                        ref.invalidate(adminStatsProvider);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? 'Médico actualizado' : 'Médico registrado'),
                              backgroundColor: MaraColors.green,
                            ),
                          );
                        }
                      } on ApiException catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
                          );
                        }
                      } finally {
                        setDialogState(() => _saving = false);
                      }
                    },
              child: Text(_saving ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDoctor(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar médico'),
        content: Text('¿Eliminar a $name del sistema?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MaraColors.rose),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await ref.read(adminRepositoryProvider).deleteAdminDoctor(id);
      ref.invalidate(adminDoctorsProvider);
      ref.invalidate(adminStatsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Médico eliminado'), backgroundColor: MaraColors.green),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MaraColors.rose),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorsAsync = ref.watch(adminDoctorsProvider);

    return AdminShell(
      title: 'Médicos',
      currentIndex: 3,
      floatingActionButton: AdminFab(
        label: 'Nuevo médico',
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => _showDoctorDialog(),
      ),
      child: doctorsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: MaraColors.green)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (doctors) {
          if (doctors.isEmpty) {
            return AdminEmptyState(
              icon: Icons.medical_services_outlined,
              title: 'Sin médicos registrados',
              subtitle: 'Agrega doctores para que los pacientes puedan agendar consultas.',
              action: FilledButton.icon(
                onPressed: () => _showDoctorDialog(),
                style: FilledButton.styleFrom(backgroundColor: MaraColors.green),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar médico'),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AdminListHeader(
                  title: '${doctors.length} médicos',
                  subtitle: 'Especialidades, tarifas y disponibilidad Medic Express.',
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: MaraColors.green,
                  onRefresh: () async => ref.invalidate(adminDoctorsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    itemCount: doctors.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = doctors[index];
                      final profile = doc['doctorProfile'] as Map<String, dynamic>?;
                      final isActive = doc['isActive'] as bool? ?? true;
                      final name = doc['name'] as String? ?? 'Médico';
                      final bio = profile?['bio']?.toString() ?? '';

                      return AdminEntityCard(
                        avatar: CircleAvatar(
                          radius: 26,
                          backgroundColor: MaraColors.green.withValues(alpha: 0.12),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'D',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: MaraColors.green,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: name,
                        subtitle: doc['email'] as String? ?? '',
                        meta:
                            '${profile?['specialty'] ?? 'Sin especialidad'} · \$${profile?['consultationFee'] ?? '0'}${bio.isNotEmpty ? '\n$bio' : ''}',
                        badge: AdminStatusBadge(active: isActive),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ActionChip(
                              icon: Icons.edit_outlined,
                              label: 'Editar',
                              color: MaraColors.green,
                              onTap: () => _showDoctorDialog(existing: doc),
                            ),
                            const SizedBox(width: 8),
                            _ActionChip(
                              icon: Icons.delete_outline_rounded,
                              label: 'Borrar',
                              color: MaraColors.rose,
                              onTap: () => _deleteDoctor(doc['id'] as String, name),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 520;
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: narrow ? 10 : 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              if (!narrow) ...[
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
