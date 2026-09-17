import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
                        imageUrl: state
                            .getProductByKey(item.productId)
                            ?.firstImageUrl,
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

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final List<ProductUnit> units;
  final String? imageUrl;
  final ValueChanged<double> onQuantityChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<double> onUnitPriceChanged;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    this.units = const [],
    this.imageUrl,
    required this.onQuantityChanged,
    required this.onUnitChanged,
    required this.onUnitPriceChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(context),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoColumn(context)),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              splashRadius: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 46,
        height: 46,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => _imagePlaceholder(theme),
                errorWidget: (_, _, _) => _imagePlaceholder(theme, icon: true),
              )
            : _imagePlaceholder(theme, icon: true),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme, {bool icon = false}) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0E0), Color(0xFFFFE8CC)],
        ),
      ),
      child: Center(
        child: icon
            ? Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              )
            : CircularProgressIndicator(
                strokeWidth: 1.5,
                color: theme.colorScheme.primary,
              ),
      ),
    );
  }

  Widget _buildInfoColumn(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildQuantityStepper(context),
            if (units.isNotEmpty) _buildUnitDropdown(theme),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${l10n.total}: Rs. ${item.lineTotal.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        if (item.discountAmount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${l10n.discount}: Rs. ${item.discountAmount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityStepper(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(context, Icons.remove, () {
            if (item.quantity <= 1) {
              onRemove();
            } else {
              onQuantityChanged(item.quantity - 1);
            }
          }),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 45),
            child: Text(
              item.quantity.toStringAsFixed(0),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          _stepperButton(
            context,
            Icons.add,
            () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildUnitDropdown(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        item.selectedUnitName ?? '',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
