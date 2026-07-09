import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import 'ai_chat_sheet.dart';

/// Sheet de contacto con soporte MaraPlus.
class SupportSheet {
  static const _phone = '+58 212 555 0100';
  static const _email = 'soporte@maraplus.com';
  static const _whatsapp = '+58 414 555 0100';

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: SafeArea(
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
              const SizedBox(height: 20),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: MaraColors.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: MaraColors.navyMid,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '¿Necesitas ayuda?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: MaraColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nuestro equipo y nuestra IA están listos para ayudarte con tus consultas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: MaraColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _SupportOption(
                icon: Icons.auto_awesome_rounded,
                iconColor: MaraColors.navyAccent,
                title: 'Maraia (IA)',
                subtitle: 'Asistente de salud inteligente (recetas, pastillas)',
                onTap: () {
                  Navigator.pop(context);
                  AiChatSheet.show(context);
                },
              ),
              const SizedBox(height: 10),
              _SupportOption(
                icon: Icons.chat_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp',
                subtitle: _whatsapp,
                onTap: () => _copy(context, _whatsapp, 'WhatsApp copiado'),
              ),
              const SizedBox(height: 10),
              _SupportOption(
                icon: Icons.phone_rounded,
                iconColor: MaraColors.navyMid,
                title: 'Llamar',
                subtitle: _phone,
                onTap: () => _copy(context, _phone, 'Teléfono copiado'),
              ),
              const SizedBox(height: 10),
              _SupportOption(
                icon: Icons.mail_outline_rounded,
                iconColor: MaraColors.green,
                title: 'Correo',
                subtitle: _email,
                onTap: () => _copy(context, _email, 'Correo copiado'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _copy(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MaraColors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  const _SupportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: MaraColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: MaraColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: MaraColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
