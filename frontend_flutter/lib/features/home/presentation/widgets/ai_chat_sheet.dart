import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/mara_theme.dart';
import '../../../../shared/widgets/mara_network_image.dart';
import '../../domain/models/catalog_models.dart';
import '../../providers/cart_provider.dart';

class ChatMessage {
  ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class AiChatSheet extends ConsumerStatefulWidget {
  const AiChatSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiChatSheet(),
    );
  }

  @override
  ConsumerState<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends ConsumerState<AiChatSheet> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida inicial
    _messages.add(
      ChatMessage(
        text: '¡Hola! Soy **Expressia**, tu asistente de salud en **Farma Express**. 🩺\n\nCuéntame qué sientes — fiebre, dolor de cabeza, resfriado — y te oriento con cuidados + productos de nuestra tienda para armar tu carrito.\n\n*Orientación general — no reemplaza consulta médica.*',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final apiClient = ref.read(apiClientProvider);

      // Preparamos el historial (excluyendo el primer mensaje de bienvenida y el último mensaje enviado para cumplir el formato del backend)
      final historyList = _messages
          .sublist(1, _messages.length - 1)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'model',
                'text': msg.text,
              })
          .toList();

      final response = await apiClient.postMap('/ai/chat', {
        'message': text,
        'history': historyList,
      });

      final reply = response['response'] as String? ?? 'Disculpa, no pude procesar la respuesta.';

      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: '❌ *Error de conexión.* No pude comunicarme con el servidor. Por favor verifica que el backend esté corriendo.',
            isUser: false,
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: SafeArea(
        child: Column(
          children: [
            // ─── Cabecera Premium ───
            Container(
              decoration: const BoxDecoration(
                gradient: MaraColors.gradientNavy,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expressia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'Asistente de Salud Inteligente',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Descargo de responsabilidad médica sutil
            Container(
              color: MaraColors.lightBlue.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: MaraColors.navyAccent, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Las respuestas no reemplazan la opinión de un profesional médico.',
                      style: TextStyle(
                        fontSize: 11,
                        color: MaraColors.navyAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Historial de Chat ───
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _ChatBubble(message: message);
                },
              ),
            ),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(MaraColors.navyAccent),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Expressia está respondiendo...',
                      style: TextStyle(
                        fontSize: 12,
                        color: MaraColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Input de Mensaje ───
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Ej: Tengo fiebre, ¿qué me recomiendas?',
                          hintStyle: TextStyle(color: MaraColors.textTertiary),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: MaraColors.gradientNavy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final regExpDoctor = RegExp(r'\[AGENDAR_CITA:([^\]]+)\]');
    final doctorMatches = regExpDoctor.allMatches(message.text).toList();

    final regExpCart = RegExp(r'\[AGREGAR_CARRITO:([^\]]+)\]');
    final cartMatches = regExpCart.allMatches(message.text).toList();

    String displayText = message.text;

    for (final match in doctorMatches) {
      displayText = displayText.replaceAll(match.group(0)!, '');
    }
    for (final match in cartMatches) {
      displayText = displayText.replaceAll(match.group(0)!, '');
    }
    displayText = displayText.trim();

    final doctorIds = doctorMatches
        .map((m) => m.group(1)?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();

    final productIds = cartMatches
        .map((m) => m.group(1)?.trim())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = message.isUser ? MaraColors.navyMid : const Color(0xFFF1F5F9);
    final textColor = message.isUser ? Colors.white : MaraColors.textPrimary;
    final borderRadius = message.isUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(16),
          );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildRichText(displayText, textColor),
          ),
          if (doctorIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    Navigator.pop(context);
                    context.go('/medic-plus?bookDoctorId=${doctorIds.first}');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MaraColors.navyAccent.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: MaraColors.navyAccent.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: MaraColors.navyAccent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '📅 Reservar cita en Medic Express',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: MaraColors.navyAccent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: MaraColors.navyAccent.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (productIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.88,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Disponible en Farma Express',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: MaraColors.navyAccent,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...productIds.map((id) => _MaraiaProductCard(productId: id)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper para renderizar negritas simples (**texto**) y viñetas básicas
  Widget _buildRichText(String text, Color baseColor) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: baseColor),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: baseColor,
        ),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: baseColor),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _MaraiaProductCard extends ConsumerStatefulWidget {
  const _MaraiaProductCard({required this.productId});
  final String productId;

  @override
  ConsumerState<_MaraiaProductCard> createState() => _MaraiaProductCardState();
}

class _MaraiaProductCardState extends ConsumerState<_MaraiaProductCard> {
  Product? _product;
  bool _loading = true;
  bool _added = false;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getMap('/products/${widget.productId}');
      if (mounted) {
        setState(() {
          _product = Product.fromJson(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 88,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MaraColors.navyAccent.withValues(alpha: 0.1)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_product == null) return const SizedBox.shrink();

    final product = _product!;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _added ? MaraColors.green : MaraColors.navyAccent.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(13)),
            child: MaraNetworkImage(
              imageUrl: product.imageUrl ?? '',
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: MaraColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: MaraColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${product.finalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: MaraColors.green,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _added || !product.inStock
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                final err =
                                    ref.read(cartProvider.notifier).addProduct(product);
                                if (err != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(err),
                                      backgroundColor: MaraColors.rose,
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _added = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} agregado al carrito'),
                                    backgroundColor: MaraColors.green,
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                        icon: Icon(
                          _added ? Icons.check_rounded : Icons.add_shopping_cart_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _added
                              ? 'Agregado'
                              : product.inStock
                                  ? 'Añadir'
                                  : 'Sin stock',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _added ? MaraColors.green : MaraColors.navyAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                          minimumSize: const Size(0, 32),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
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
