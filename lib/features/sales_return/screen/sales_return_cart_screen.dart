import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../repositories/discount_group_repository.dart';
import '../provider/sales_return_provider.dart';

class SalesReturnCartScreen extends ConsumerStatefulWidget {
  const SalesReturnCartScreen({super.key});

  @override
  ConsumerState<SalesReturnCartScreen> createState() =>
      _SalesReturnCartScreenState();
}

class _SalesReturnCartScreenState extends ConsumerState<SalesReturnCartScreen> {
  // Commented out: discount value controller disabled for now.
  // final _discountValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(salesReturnProvider).saved) {
        ref.read(salesReturnProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    // _discountValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesReturnProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.cart} (${state.items.length})'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton.icon(
              onPressed: () =>
                  ref.read(salesReturnProvider.notifier).clearItems(),
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: Text(l10n.clear),
            ),
        ],
      ),
      body: state.items.isEmpty
          ? Center(
              child: Text(
                l10n.cartIsEmpty,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.customer,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSelectedCustomerCard(state, theme),
                const SizedBox(height: 24),
                _buildItemsSection(state, theme, l10n),
                const SizedBox(height: 16),
                // Commented out: volume discount section disabled for now.
                // _buildHeaderDiscountSection(state, theme, l10n),
                const SizedBox(height: 16),
                _buildTotalsCard(state, theme, l10n),
                const SizedBox(height: 24),
                Text(
                  l10n.additionalDetails,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          decoration: InputDecoration(
                            labelText: l10n.reason,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            ref
                                .read(salesReturnProvider.notifier)
                                .setReason(value.isEmpty ? null : value);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.isSaving
                      ? null
                      : () => _saveSalesReturn(context),
                  icon: state.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    state.isSaving ? l10n.saving : l10n.saveSalesReturn,
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectedCustomerCard(SalesReturnState state, ThemeData theme) {
    final customer = state.selectedCustomer;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                customer != null && customer.name.isNotEmpty
                    ? customer.name[0].toUpperCase()
                    : '?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer?.name ?? '',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (customer?.discountGroupId?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 2),
                    ..._discountGroupLabel(context, customer!.discountGroupId!),
                  ],
                  if (customer != null &&
                      customer.phone != null &&
                      customer.phone!.isNotEmpty)
                    Text(
                      customer.phone!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  if (customer != null &&
                      customer.address != null &&
                      customer.address!.isNotEmpty)
                    Text(
                      customer.address!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
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

  List<Widget> _discountGroupLabel(BuildContext context, String groupId) {
    final name = ref.watch(discountGroupNameProvider(groupId)).valueOrNull;
    if (name == null || name.isEmpty) return const [SizedBox.shrink()];
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return [
      Text(
        '${l10n.discountGroup} - $name',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    ];
  }

  Widget _buildItemsSection(
    SalesReturnState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (state.items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              l10n.noProductsAdded,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.addedProducts(state.items.length.toString()),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < state.items.length; i++)
          _buildItemCard(state, theme, l10n, i),
      ],
    );
  }

  Widget _buildItemCard(
    SalesReturnState state,
    ThemeData theme,
    AppLocalizations l10n,
    int index,
  ) {
    final item = state.items[index];
    final product = state.products
        .where((p) => p.serverId == item.productId)
        .firstOrNull;
    final notifier = ref.read(salesReturnProvider.notifier);

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
            _buildItemThumbnail(product?.firstImageUrl),
            const SizedBox(width: 10),
            Expanded(child: _buildItemInfoColumn(state, theme, l10n, index)),
            IconButton(
              onPressed: () => notifier.removeItem(index),
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

  Widget _buildItemThumbnail(String? imageUrl) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 46,
        height: 46,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => _itemImagePlaceholder(theme),
                errorWidget: (_, _, _) =>
                    _itemImagePlaceholder(theme, icon: true),
              )
            : _itemImagePlaceholder(theme, icon: true),
      ),
    );
  }

  Widget _itemImagePlaceholder(ThemeData theme, {bool icon = false}) {
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

  Widget _buildItemInfoColumn(
    SalesReturnState state,
    ThemeData theme,
    AppLocalizations l10n,
    int index,
  ) {
    final item = state.items[index];

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
            _buildItemQuantityStepper(index),
            if (item.unit != null && item.unit!.isNotEmpty)
              _buildItemUnitPill(item.unit!),
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

  Widget _buildItemQuantityStepper(int index) {
    final item = ref.read(salesReturnProvider).items[index];
    final notifier = ref.read(salesReturnProvider.notifier);
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
          _itemStepButton(context, Icons.remove, () {
            notifier.decrementItemQuantity(index);
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
          _itemStepButton(context, Icons.add, () {
            notifier.incrementItemQuantity(index);
          }),
        ],
      ),
    );
  }

  Widget _itemStepButton(
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

  Widget _buildItemUnitPill(String unitName) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Text(
        unitName,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTotalsCard(
    SalesReturnState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _totalRow(
              l10n.grossAmount,
              state.totalGrossAmountIncTax,
              theme,
              null,
            ),
            if (state.totalProductDiscountIncTax + state.discountAmount > 0)
              ...[
                const SizedBox(height: 4),
                _totalRow(
                  l10n.discount,
                  -(state.totalProductDiscountIncTax + state.discountAmount),
                  theme,
                  theme.colorScheme.error,
                ),
              ],
            if (state.totalTaxAmount > 0) ...[
              const SizedBox(height: 4),
              _totalRow(
                l10n.tax,
                state.totalTaxAmount,
                theme,
                theme.colorScheme.onSurfaceVariant,
              ),
            ],
            const Divider(),
            _totalRow(
              l10n.totalAmount,
              state.netTotalIncTax,
              theme,
              theme.colorScheme.primary,
              bold: true,
            ),
            // Commented out: payment modal disabled for now.
            // const SizedBox(height: 12),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton.icon(
            //     onPressed: () => _showPaymentModal(context),
            //     icon: const Icon(Icons.payment, size: 20),
            //     label: Text(l10n.makePayment),
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: theme.colorScheme.secondaryContainer,
            //       foregroundColor: theme.colorScheme.onSecondaryContainer,
            //       minimumSize: const Size(double.infinity, 48),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(8),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(
    String label,
    double amount,
    ThemeData theme,
    Color? color, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            amount >= 0
                ? 'Rs. ${amount.toStringAsFixed(2)}'
                : '- Rs. ${(-amount).toStringAsFixed(2)}',
            style:
                (bold
                        ? theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(
                      color: color,
                      fontWeight: bold ? FontWeight.w600 : null,
                    ),
          ),
        ],
      ),
    );
  }

  // Commented out: volume discount section disabled for now.
  // Widget _buildHeaderDiscountSection(
  //   SalesReturnState state,
  //   ThemeData theme,
  //   AppLocalizations l10n,
  // ) {
  //   return Card(
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.stretch,
  //         children: [
  //           Text(
  //             l10n.volumeDiscount,
  //             style: theme.textTheme.titleSmall?.copyWith(
  //               fontWeight: FontWeight.w600,
  //               color: theme.colorScheme.onSurfaceVariant,
  //             ),
  //           ),
  //           const SizedBox(height: 12),
  //           Row(
  //             children: [
  //               Expanded(
  //                 flex: 2,
  //                 child: TextField(
  //                   controller: _discountValueController,
  //                   keyboardType:
  //                       const TextInputType.numberWithOptions(decimal: true),
  //                   inputFormatters: [
  //                     FilteringTextInputFormatter.allow(
  //                       RegExp(r'^\d*\.?\d{0,2}'),
  //                     ),
  //                   ],
  //                   decoration: InputDecoration(
  //                     labelText: l10n.value,
  //                     hintText: '0',
  //                     border: const OutlineInputBorder(),
  //                     isDense: true,
  //                   ),
  //                   onChanged: (value) {
  //                     final val = double.tryParse(value) ?? 0;
  //                     ref
  //                         .read(salesReturnProvider.notifier)
  //                         .setDiscountValue(val);
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 flex: 2,
  //                 child: DropdownButtonFormField<String?>(
  //                   isExpanded: true,
  //                   initialValue: state.discountType,
  //                   decoration: InputDecoration(
  //                     labelText: l10n.discountType,
  //                     border: const OutlineInputBorder(),
  //                     isDense: true,
  //                   ),
  //                   items: [
  //                     DropdownMenuItem(value: null, child: Text(l10n.none)),
  //                     DropdownMenuItem(
  //                       value: 'amount',
  //                       child: Text(l10n.amountRs),
  //                     ),
  //                     DropdownMenuItem(
  //                       value: 'percent',
  //                       child: Text(l10n.percent),
  //                     ),
  //                   ],
  //                   onChanged: (value) {
  //                     ref
  //                         .read(salesReturnProvider.notifier)
  //                         .setDiscountType(value);
  //                     if (value == null) {
  //                       _discountValueController.clear();
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // Commented out: payment modal disabled for now.
  // void _showPaymentModal(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (ctx) => _PaymentModalSheet(),
  //   );
  // }

  Future<void> _saveSalesReturn(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final notifier = ref.read(salesReturnProvider.notifier);
    final success = await notifier.saveSalesReturn(l10n);

    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      final errMsg = ref.read(salesReturnProvider).error;
      print(errMsg);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errMsg ?? AppLocalizations.of(context)!.failedToSaveSalesReturn,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

// Commented out: payment modal sheet disabled for now.
// class _PaymentModalSheet extends ConsumerStatefulWidget {
//   @override
//   ConsumerState<_PaymentModalSheet> createState() => _PaymentModalSheetState();
// }
//
// class _PaymentModalSheetState extends ConsumerState<_PaymentModalSheet> {
//   late final TextEditingController _amountController;
//
//   @override
//   void initState() {
//     super.initState();
//     final state = ref.read(salesReturnProvider);
//     final paymentEntry = state.paymentEntries.isNotEmpty
//         ? state.paymentEntries.first
//         : null;
//     final paymentAmount = paymentEntry?.amount ?? state.netTotalIncTax;
//     _amountController = TextEditingController(
//       text: paymentAmount > 0 ? paymentAmount.toStringAsFixed(2) : '',
//     );
//   }
//
//   @override
//   void dispose() {
//     _amountController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(salesReturnProvider);
//     final theme = Theme.of(context);
//     final l10n = AppLocalizations.of(context)!;
//
//     final paymentEntry = state.paymentEntries.isNotEmpty
//         ? state.paymentEntries.first
//         : null;
//     final paymentModeId = paymentEntry?.paymentModeId ?? '';
//     final paymentAmount = paymentEntry?.amount ?? state.netTotalIncTax;
//
//     final currentText = _amountController.text;
//     final expectedText = paymentAmount > 0
//         ? paymentAmount.toStringAsFixed(2)
//         : '';
//     if (currentText != expectedText && !_amountController.selection.isValid) {
//       _amountController.text = expectedText;
//     }
//
//     return SafeArea(
//       child: Padding(
//         padding: EdgeInsets.only(
//           left: 16,
//           right: 16,
//           top: 16,
//           bottom: MediaQuery.of(context).viewInsets.bottom + 16,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     l10n.paymentDetails,
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close),
//                   onPressed: () => Navigator.of(context).pop(),
//                 ),
//               ],
//             ),
//             const Divider(),
//             const SizedBox(height: 16),
//             DropdownButtonFormField<String>(
//               initialValue: paymentModeId.isNotEmpty ? paymentModeId : null,
//               decoration: InputDecoration(
//                 labelText: l10n.paymentMode,
//                 border: const OutlineInputBorder(),
//                 isDense: true,
//               ),
//               menuMaxHeight: 200,
//               items: state.paymentModes.map((mode) {
//                 return DropdownMenuItem(
//                   value: mode.serverId,
//                   child: Text(mode.name),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 final mode = state.paymentModes
//                     .where((m) => m.serverId == value)
//                     .firstOrNull;
//                 if (state.paymentEntries.isEmpty) {
//                   ref.read(salesReturnProvider.notifier).addPaymentEntry();
//                 }
//                 ref
//                     .read(salesReturnProvider.notifier)
//                     .updatePaymentEntryMode(0, value, mode?.name);
//               },
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               keyboardType: const TextInputType.numberWithOptions(
//                 decimal: true,
//               ),
//               inputFormatters: [
//                 FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
//               ],
//               decoration: InputDecoration(
//                 labelText: l10n.amount,
//                 prefixText: 'Rs. ',
//                 border: const OutlineInputBorder(),
//                 isDense: true,
//               ),
//               controller: _amountController,
//               onChanged: (value) {
//                 final parsed = double.tryParse(value);
//                 if (parsed == null) {
//                   if (state.paymentEntries.isNotEmpty) {
//                     ref
//                         .read(salesReturnProvider.notifier)
//                         .updatePaymentEntryAmount(0, 0);
//                   }
//                   return;
//                 }
//                 final maxAllowed = state.netTotalIncTax;
//                 final clamped = parsed > maxAllowed ? maxAllowed : parsed;
//                 if (state.paymentEntries.isEmpty) {
//                   ref.read(salesReturnProvider.notifier).addPaymentEntry();
//                 }
//                 ref
//                     .read(salesReturnProvider.notifier)
//                     .updatePaymentEntryAmount(0, clamped);
//               },
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.surfaceContainerHighest.withValues(
//                   alpha: 0.3,
//                 ),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${l10n.total}:',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         'Rs. ${state.netTotalIncTax.toStringAsFixed(2)}',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${l10n.paid}:',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         'Rs. ${state.totalPaidAmount.toStringAsFixed(2)}',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: theme.colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '${l10n.remaining}:',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: state.remainingAmountIncTax > 0
//                               ? theme.colorScheme.error
//                               : theme.colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       Text(
//                         'Rs. ${state.remainingAmountIncTax.toStringAsFixed(2)}',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: state.remainingAmountIncTax > 0
//                               ? theme.colorScheme.error
//                               : theme.colorScheme.primary,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 16),
//             FilledButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(l10n.done),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
