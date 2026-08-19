import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/product_unit.dart';
import '../models/cart_item.dart';
import '../provider/delivery_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryFormProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    final cartItems = state.cart.entries.map((e) {
      final product = state.getProductByKey(e.key);
      return CartItem(
        productId: e.key,
        productName: product?.localizedName(langCode) ?? l10n.unknown,
        quantity: e.value,
        unitPrice: state.getUnitPrice(e.key),
        discountAmount: state.productDiscounts[e.key] ?? 0,
        selectedUnitId: state.getSelectedUnitId(e.key) ?? product?.unitId,
        selectedUnitName: state.getSelectedUnitName(e.key) ?? product?.unit,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.cart} (${cartItems.length})'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(deliveryFormProvider.notifier).clearCart(),
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: Text(l10n.clear),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Text(
                l10n.cartIsEmpty,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final units = state.getProductUnits(item.productId);
                      return _CartItemCard(
                        item: item,
                        units: units,
                        onQuantityChanged: (qty) {
                          ref
                              .read(deliveryFormProvider.notifier)
                              .updateCartQuantity(item.productId, qty);
                        },
                        onUnitChanged: (unitId) {
                          ref
                              .read(deliveryFormProvider.notifier)
                              .setSelectedUnit(item.productId, unitId);
                        },
                        onUnitPriceChanged: (price) {
                          ref
                              .read(deliveryFormProvider.notifier)
                              .setCustomPrice(item.productId, price);
                        },
                        onRemove: () {
                          ref
                              .read(deliveryFormProvider.notifier)
                              .removeFromCart(item.productId);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                l10n.total,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Rs. ${state.estimatedTotal.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: state.isValid
                                ? () => GoRouter.of(context).pop(true)
                                : null,
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(l10n.continueLabel),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final List<ProductUnit> units;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<double> onUnitPriceChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    this.units = const [],
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onUnitPriceChanged,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  late TextEditingController _qtyController;
  bool _isQtyFocused = false;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(0),
    );
  }

  @override
  void didUpdateWidget(_CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isQtyFocused) {
      _qtyController.text = widget.item.quantity.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  void _applyQty() {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty != widget.item.quantity) {
      widget.onQuantityChanged(qty);
    }
    setState(() => _isQtyFocused = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.productName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.units.length > 1)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        key: ValueKey(widget.item.selectedUnitId ?? widget.units.first.unitId),
                        value: widget.item.selectedUnitId ?? widget.units.first.unitId,
                        isDense: true,
                        items: widget.units.map((u) {
                          return DropdownMenuItem(
                            value: u.unitId,
                            child: Text(u.unitName, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) widget.onUnitChanged(value);
                        },
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    if (widget.item.quantity <= 1) {
                      widget.onRemove();
                    } else {
                      widget.onQuantityChanged(widget.item.quantity - 1);
                    }
                  },
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(
                  width: 48,
                  child: Focus(
                    onFocusChange: (focused) {
                      if (!focused) _applyQty();
                      setState(() => _isQtyFocused = focused);
                    },
                    child: TextField(
                      controller: _qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,1}'),
                        ),
                      ],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        labelText: l10n.qty,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      onChanged: (value) {
                        final qty = double.tryParse(value) ?? 0;
                        widget.onQuantityChanged(qty);
                      },
                      onSubmitted: (_) => _applyQty(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  onPressed: () =>
                      widget.onQuantityChanged(widget.item.quantity + 1),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Rs. ${widget.item.unitPrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  l10n.lineTotal,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Rs. ${widget.item.lineTotal.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (widget.item.discountAmount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Spacer(),
                    Text(
                      '${l10n.discount}: -Rs. ${widget.item.discountAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
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

  // Commented out: rate/price editor disabled for now.
  // void _showPriceEditor(BuildContext context, ThemeData theme) {
  //   final controller = TextEditingController(
  //     text: widget.item.unitPrice.toStringAsFixed(2),
  //   );
  //   final l10n = AppLocalizations.of(context)!;
  //
  //   showDialog(
  //     context: context,
  //     builder: (ctx) => AlertDialog(
  //       title: Text('${l10n.editPrice}: ${widget.item.productName}'),
  //       content: TextField(
  //         controller: controller,
  //         keyboardType: const TextInputType.numberWithOptions(decimal: true),
  //         inputFormatters: [
  //           FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  //         ],
  //         decoration: InputDecoration(
  //           labelText: l10n.unitPrice,
  //           prefixText: 'Rs. ',
  //           border: const OutlineInputBorder(),
  //         ),
  //         autofocus: true,
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(ctx),
  //           child: Text(l10n.cancel),
  //         ),
  //         FilledButton(
  //           onPressed: () {
  //             final price = double.tryParse(controller.text) ?? 0;
  //             if (price > 0) {
  //               widget.onUnitPriceChanged(price);
  //             }
  //             Navigator.pop(ctx);
  //           },
  //           child: Text(l10n.save),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
