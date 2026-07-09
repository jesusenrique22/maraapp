import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/mara_theme.dart';
import '../../../branches/domain/branch_models.dart';
import '../../providers/cart_provider.dart';
import 'home_header.dart';

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({
    super.key,
    required this.items,
    required this.subtotal,
    required this.branches,
    this.selectedBranch,
    required this.onConfirm,
  });

  final List<CartItem> items;
  final double subtotal;
  final List<Branch> branches;
  final Branch? selectedBranch;
  final Future<void> Function({
    required FulfillmentType fulfillmentType,
    required String branchId,
    String? deliveryAddress,
    String? notes,
  }) onConfirm;

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  late FulfillmentType _fulfillmentType;
  Branch? _pickupBranch;

  @override
  void initState() {
    super.initState();
    _fulfillmentType = FulfillmentType.delivery;
    _pickupBranch = widget.selectedBranch ??
        (widget.branches.where((b) => b.isMain).isNotEmpty
            ? widget.branches.firstWhere((b) => b.isMain)
            : (widget.branches.isNotEmpty ? widget.branches.first : null));
  }

  double get _deliveryFee {
    if (_fulfillmentType == FulfillmentType.pickup) return 0;
    return widget.subtotal > 20 ? 0 : 2;
  }

  double get _total => widget.subtotal + _deliveryFee;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    HapticFeedback.mediumImpact();
    if (_fulfillmentType == FulfillmentType.delivery) {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Ingresa tu dirección de entrega'),
            ]),
            backgroundColor: MaraColors.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
    } else if (_pickupBranch == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Selecciona una sucursal para retiro'),
          ]),
          backgroundColor: MaraColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final branchId = _fulfillmentType == FulfillmentType.pickup
        ? _pickupBranch?.id
        : widget.selectedBranch?.id;

    if (branchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Selecciona una sucursal para continuar'),
          ]),
          backgroundColor: MaraColors.rose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onConfirm(
        fulfillmentType: _fulfillmentType,
        branchId: branchId,
        deliveryAddress: _fulfillmentType == FulfillmentType.delivery
            ? _addressController.text.trim()
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Clean Header ──────────────────────────────────────────────
            _CleanHeader(itemCount: widget.items.length),

            // ── Scrollable body ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Items Summary
                    const _SectionLabel(label: 'Resumen del pedido'),
                    const SizedBox(height: 10),
                    _ItemsSummaryCard(items: widget.items),
                    const SizedBox(height: 24),

                    // 2. Fulfillment method
                    const _SectionLabel(label: 'Método de entrega'),
                    const SizedBox(height: 10),
                    _FulfillmentToggle(
                      selected: _fulfillmentType,
                      onChanged: (v) => setState(() => _fulfillmentType = v),
                    ),
                    const SizedBox(height: 20),

                    // 3. Delivery address or Branch picker
                    if (_fulfillmentType == FulfillmentType.delivery) ...[
                      if (widget.selectedBranch != null) ...[
                        _DispatchBanner(branch: widget.selectedBranch!),
                        const SizedBox(height: 14),
                      ],
                      const _SectionLabel(label: 'Dirección de entrega'),
                      const SizedBox(height: 10),
                      _StyledField(
                        controller: _addressController,
                        hint: 'Ej: Av. Principal, Edificio Sol, Piso 3',
                        maxLines: 2,
                      ),
                    ] else ...[
                      const _SectionLabel(label: 'Selecciona la sucursal de retiro'),
                      const SizedBox(height: 10),
                      ...widget.branches.map(
                        (branch) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _BranchCard(
                            branch: branch,
                            isSelected: _pickupBranch?.id == branch.id,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _pickupBranch = branch);
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // 4. Notes
                    const _SectionLabel(label: 'Notas (opcional)'),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: _notesController,
                      hint: 'Instrucciones especiales para tu pedido...',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Panel ─────────────────────────────────────────
            _StickyBottomPanel(
              subtotal: widget.subtotal,
              deliveryFee: _deliveryFee,
              total: _total,
              fulfillmentType: _fulfillmentType,
              isSubmitting: _isSubmitting,
              onConfirm: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Clean Header
// ─────────────────────────────────────────────────────────────────────────────
class _CleanHeader extends StatelessWidget {
  const _CleanHeader({required this.itemCount});
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag pill
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Header content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Finalizar compra',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: MaraColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemCount producto${itemCount == 1 ? '' : 's'} a comprar',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: MaraColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: MaraColors.textPrimary,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Items Summary Card
// ─────────────────────────────────────────────────────────────────────────────
class _ItemsSummaryCard extends StatelessWidget {
  const _ItemsSummaryCard({required this.items});
  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: items.map((item) {
          final isLast = item == items.last;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ProductImage(
                        imageUrl: item.product.imageUrl,
                        categorySlug: item.product.category.slug,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: MaraColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.quantity} x \$${item.product.finalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: MaraColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Price
                    Text(
                      '\$${(item.product.finalPrice * item.quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: MaraColors.navyAccent,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fulfillment Toggle
// ─────────────────────────────────────────────────────────────────────────────
class _FulfillmentToggle extends StatelessWidget {
  const _FulfillmentToggle({required this.selected, required this.onChanged});
  final FulfillmentType selected;
  final ValueChanged<FulfillmentType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            icon: Icons.delivery_dining_rounded,
            label: 'Delivery',
            isSelected: selected == FulfillmentType.delivery,
            onTap: () => onChanged(FulfillmentType.delivery),
          ),
          _ToggleOption(
            icon: Icons.storefront_rounded,
            label: 'Retiro en tienda',
            isSelected: selected == FulfillmentType.pickup,
            onTap: () => onChanged(FulfillmentType.pickup),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? MaraColors.lightBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? MaraColors.navyAccent : MaraColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? MaraColors.navyAccent : MaraColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dispatch Banner
// ─────────────────────────────────────────────────────────────────────────────
class _DispatchBanner extends StatelessWidget {
  const _DispatchBanner({required this.branch});
  final Branch branch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, size: 18, color: MaraColors.navyAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Despacho desde ${branch.name}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: MaraColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Styled Text Input (clean, white, with border on focus)
// ─────────────────────────────────────────────────────────────────────────────
class _StyledField extends StatelessWidget {
  const _StyledField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: MaraColors.textPrimary,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: MaraColors.textTertiary,
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MaraColors.navyAccent, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Branch Card
// ─────────────────────────────────────────────────────────────────────────────
class _BranchCard extends StatelessWidget {
  const _BranchCard({
    required this.branch,
    required this.isSelected,
    required this.onTap,
  });
  final Branch branch;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? MaraColors.navyAccent : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected ? MaraColors.navyAccent : MaraColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: MaraColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    branch.fullAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: MaraColors.textSecondary,
                      fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Bottom Panel
// ─────────────────────────────────────────────────────────────────────────────
class _StickyBottomPanel extends StatelessWidget {
  const _StickyBottomPanel({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.fulfillmentType,
    required this.isSubmitting,
    required this.onConfirm,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;
  final FulfillmentType fulfillmentType;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Totals
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _TotalRow(
                  label: 'Subtotal',
                  value: '\$${subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _TotalRow(
                  label: fulfillmentType == FulfillmentType.pickup
                      ? 'Retiro en tienda'
                      : 'Envío',
                  value: deliveryFee == 0
                      ? 'Gratis'
                      : '\$${deliveryFee.toStringAsFixed(2)}',
                  valueColor: deliveryFee == 0 ? MaraColors.green : null,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _TotalRow(
                  label: 'Total a pagar',
                  value: '\$${total.toStringAsFixed(2)}',
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Confirm Button (clean flat blue)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isSubmitting ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: MaraColors.navyAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Confirmar pedido',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            fontSize: bold ? 14.5 : 13.5,
            color: bold ? MaraColors.textPrimary : MaraColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: bold ? 18 : 14,
            color: valueColor ??
                (bold ? MaraColors.navyAccent : MaraColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
