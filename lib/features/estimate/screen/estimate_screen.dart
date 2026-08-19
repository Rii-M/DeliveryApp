import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/payment_entry.dart';
import '../../../models/payment_mode.dart';
import '../../delivery/provider/delivery_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../../../repositories/discount_group_repository.dart';
import '../provider/estimate_provider.dart';

class EstimateScreen extends ConsumerStatefulWidget {
  final int? deliveryId;

  const EstimateScreen({super.key, this.deliveryId});

  @override
  ConsumerState<EstimateScreen> createState() => _EstimateScreenState();
}

class _EstimateScreenState extends ConsumerState<EstimateScreen> {
  final _paidAmountController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final langCode = Localizations.localeOf(context).languageCode;
      if (widget.deliveryId != null) {
        ref.read(estimateProvider.notifier).loadDelivery(widget.deliveryId!, languageCode: langCode);
      } else {
        _initFromDeliveryForm(ref, langCode);
      }
    });
  }

  void _initFromDeliveryForm(WidgetRef ref, String langCode) {
    final deliveryForm = ref.read(deliveryFormProvider);
    if (deliveryForm.cart.isEmpty) {
      context.go('/delivery');
      return;
    }

    final items = deliveryForm.cart.entries.map((e) {
      final product = deliveryForm.getProductByKey(e.key);
      return EstimateItemView(
        productId: product?.serverId ?? e.key.split('|').first,
        productName: product?.localizedName(langCode) ?? AppLocalizations.of(context)!.unknown,
        quantity: e.value,
        unitPrice: deliveryForm.getUnitPrice(e.key),
        discountAmount: deliveryForm.productDiscounts[e.key] ?? 0,
        taxableType: product?.taxable ?? 0,
        unitId: deliveryForm.getSelectedUnitId(e.key) ?? product?.unitId,
        unitName: deliveryForm.getSelectedUnitName(e.key) ?? product?.unit,
      );
    }).toList();

    ref
        .read(estimateProvider.notifier)
        .initializeFromDeliveryForm(
          items: items,
          paymentModes: deliveryForm.paymentModes,
          customer: deliveryForm.selectedCustomer,
        );
    ref.read(estimateProvider.notifier).loadCustomers();
  }

  @override
  void dispose() {
    _paidAmountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _syncControllers(EstimateState state) {
    if (state.isLoadingDelivery) {
      _controllersInitialized = false;
      return;
    }
    if (!_controllersInitialized) {
      _paidAmountController.text = state.paidAmount > 0
          ? state.paidAmount.toStringAsFixed(2)
          : '';
      _remarksController.text = state.remarks ?? '';
      _controllersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    _syncControllers(state);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.billing)),
      body: _buildBody(state, theme, l10n),
    );
  }

  Widget _buildBody(
    EstimateState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    if (state.isLoadingDelivery) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.saved) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && context.mounted) {
            ref.read(estimateProvider.notifier).reset();
            context.pop();
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.invoiceSavedSuccessfully,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  ref.read(estimateProvider.notifier).reset();
                  context.pop();
                },
                child: Text(l10n.newDelivery),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ref.read(estimateProvider.notifier).reset();
                  context.go('/sales-return');
                },
                child: Text(l10n.goToSalesReturn),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (state.customer != null) ...[
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      state.customer!.name.isNotEmpty
                          ? state.customer!.name[0].toUpperCase()
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
                          state.customer!.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (state.customer!.discountGroupId?.isNotEmpty ??
                            false) ...[
                          const SizedBox(height: 2),
                          ..._discountGroupLabel(
                            context,
                            state.customer!.discountGroupId!,
                          ),
                        ],
                        if (state.customer!.phone != null &&
                            state.customer!.phone!.isNotEmpty)
                          Text(
                            state.customer!.phone!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        if (state.customer!.address != null &&
                            state.customer!.address!.isNotEmpty)
                          Text(
                            state.customer!.address!,
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
          ),
          const SizedBox(height: 16),
        ] else ...[
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        l10n.selectCustomer,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchCustomer,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.customerSearchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => ref
                                  .read(estimateProvider.notifier)
                                  .setCustomerSearchQuery(''),
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) => ref
                        .read(estimateProvider.notifier)
                        .setCustomerSearchQuery(value),
                  ),
                  if (state.customerSearchQuery.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...state.filteredCustomers.map(
                      (c) => ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(c.name, style: theme.textTheme.bodyMedium),
                        subtitle: c.phone != null && c.phone!.isNotEmpty
                            ? Text(c.phone!, style: theme.textTheme.bodySmall)
                            : null,
                        onTap: () => ref
                            .read(estimateProvider.notifier)
                            .selectCustomer(c),
                      ),
                    ),
                    if (state.filteredCustomers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          l10n.noCustomersFound,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        Text(
          l10n.items,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...state.items.map((item) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.qtyWithPrice(
                            item.rateIncTax.toStringAsFixed(2),
                            item.quantity.toStringAsFixed(0),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (item.discountAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Discount: -Rs. ${item.discountAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${item.netAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.grossAmount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Rs. ${state.totalGrossAmountIncTax.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Commented out: volume discount input disabled for now.
                // Row(
                //   children: [
                //     Expanded(
                //       flex: 3,
                //       child: DropdownButtonFormField<String>(
                //         isExpanded: true,
                //         initialValue: state.discountType,
                //         decoration: InputDecoration(
                //           labelText: l10n.discountType,
                //           border: const OutlineInputBorder(),
                //           isDense: true,
                //           contentPadding: EdgeInsets.symmetric(
                //             horizontal: 8,
                //             vertical: 10,
                //           ),
                //         ),
                //         items: [
                //           DropdownMenuItem(value: null, child: Text(l10n.none)),
                //           DropdownMenuItem(
                //             value: 'amount',
                //             child: Text(l10n.amountRs),
                //           ),
                //           DropdownMenuItem(
                //             value: 'percent',
                //             child: Text(l10n.percent),
                //           ),
                //         ],
                //         onChanged: (value) {
                //           ref
                //               .read(estimateProvider.notifier)
                //               .setDiscountType(value);
                //         },
                //       ),
                //     ),
                //     if (state.discountType != null) ...[
                //       const SizedBox(width: 8),
                //       Expanded(
                //         flex: 2,
                //         child: TextField(
                //           keyboardType: const TextInputType.numberWithOptions(
                //             decimal: true,
                //           ),
                //           inputFormatters: [
                //             FilteringTextInputFormatter.allow(
                //               RegExp(r'^\d+\.?\d{0,2}'),
                //             ),
                //           ],
                //           decoration: InputDecoration(
                //             labelText: state.discountType == 'percent'
                //                 ? l10n.percent
                //                 : l10n.amountRs,
                //             border: const OutlineInputBorder(),
                //             isDense: true,
                //             contentPadding: const EdgeInsets.symmetric(
                //               horizontal: 8,
                //               vertical: 10,
                //             ),
                //             suffixText: state.discountType == 'percent'
                //                 ? '%'
                //                 : 'Rs.',
                //           ),
                //           onChanged: (value) {
                //             final val = double.tryParse(value) ?? 0;
                //             ref
                //                 .read(estimateProvider.notifier)
                //                 .setDiscountValue(val);
                //           },
                //         ),
                //       ),
                //     ],
                //   ],
                // ),
                if (state.totalProductDiscount + state.discountAmount > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.discount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- Rs. ${(state.totalProductDiscount + state.discountAmount).toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (state.totalTax > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.tax,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Rs. ${state.totalTax.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalAmount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Rs. ${state.netTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showPaymentModal(context),
          icon: const Icon(Icons.payment, size: 20),
          label: Text(l10n.makePayment),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.remarksOptional,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.remarksOptional,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                ref
                    .read(estimateProvider.notifier)
                    .setRemarks(value.isEmpty ? null : value);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: state.isSaving ? null : () => _saveInvoice(context),
          icon: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(state.isSaving ? l10n.saving : l10n.saveInvoice),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
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

  Future<void> _saveInvoice(BuildContext context) async {
    
  final state = ref.read(estimateProvider);
  if (state.remainingAmount > 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pleaseMakeFullPayment),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    _showPaymentModal(context);
    return;
  }

  if(state.customer == null)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.selectCustomer),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }

   if(state.items.isEmpty)
  {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.pleaseSelectItems),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
    return;
  }

  final hasUnsetPaymode=state.paymentEntries.any((e)=>e.paymentModeId == null || e.paymentModeId!.isEmpty);
              if (hasUnsetPaymode) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Please select paymode'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
               } 
    
    final success = await ref.read(estimateProvider.notifier).saveInvoice();

    if (!context.mounted) return;

    if (success) {
      ref.read(deliveryFormProvider.notifier).resetForm();
      ref.read(deliveryFormProvider.notifier).refreshProducts(); 
      ref.read(syncProvider.notifier).refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.invoiceSavedSuccessfully),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else {
  //     final state = ref.read(estimateProvider);
  // if (state.paymentEntries.isEmpty) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Please add a payment mode before saving'),
  //       backgroundColor: Theme.of(context).colorScheme.error,
  //     ),
  //   );
  //   _showPaymentModal(context);
  //  } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveInvoice),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  //  }
  }

  void _showPaymentModal(BuildContext context) {
  final s = ref.read(estimateProvider);
  if (s.paymentEntries.isEmpty && s.remainingAmount > 0) {
    ref.read(estimateProvider.notifier).addPaymentEntry();
  }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _PaymentModalSheet(),
    );
  }
}

class _PaymentEntryRow extends ConsumerStatefulWidget {
  final int index;
  final PaymentEntry payment;
  final List<PaymentMode> paymentModes;
  final AppLocalizations l10n;

  const _PaymentEntryRow({
    required this.index,
    required this.payment,
    required this.paymentModes,
    required this.l10n,
    super.key,
  });

  @override
  ConsumerState<_PaymentEntryRow> createState() => _PaymentEntryRowState();
}

class _PaymentEntryRowState extends ConsumerState<_PaymentEntryRow> {
  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment.amount > 0 ? widget.payment.amount.toStringAsFixed(2) : '',
    );
    _amountFocusNode = FocusNode();
    _amountFocusNode.addListener(() {
      if (!_amountFocusNode.hasFocus) {
        _isTyping = false;
        final current = double.tryParse(_amountController.text) ?? 0;
        if (current > 0) {
           _amountController.text = current.toStringAsFixed(2);
          ref.read(estimateProvider.notifier)
              .updatePaymentEntryAmount(widget.index, current);
        }
      } else {
        _isTyping = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _PaymentEntryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isTyping && widget.payment.amount != oldWidget.payment.amount) {
      final newText = widget.payment.amount > 0 ? widget.payment.amount.toStringAsFixed(2) : '';
      if (_amountController.text != newText) {
        _amountController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children:[
 
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: widget.payment.paymentModeId,
              decoration: InputDecoration(
                labelText: widget.l10n.paymentMode,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: widget.paymentModes.map((mode) {
                return DropdownMenuItem(
                  value: mode.serverId,
                  child: Text(mode.name),
                );
              }).toList(),
              onChanged: (value) {
                final mode = widget.paymentModes
                    .where((m) => m.serverId == value)
                    .firstOrNull;
                ref.read(estimateProvider.notifier)
                    .updatePaymentEntryMode(widget.index, value, mode?.name);
              },
            ),
          
       
        
        
          const SizedBox(height: 8),
          Row(
            children: [
           Expanded(
            flex: 2,
            child: TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              focusNode: _amountFocusNode,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: widget.l10n.amount,
                prefixText: 'Rs. ',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              controller: _amountController,
              onChanged: (value) {
                final parsed = double.tryParse(value);
                if (parsed == null) {
                  ref.read(estimateProvider.notifier)
                      .updatePaymentEntryAmount(widget.index, 0);
                  return;
                }
                ref.read(estimateProvider.notifier)
                    .updatePaymentEntryAmount(widget.index, parsed);
              },
            ),
          ),
          const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error),
              onPressed: () {
                ref.read(estimateProvider.notifier).removePaymentEntry(widget.index);
              },
            ),
          ],
          ),
        ],
      ),
    );
  }
}

class _PaymentModalSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(estimateProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.paymentDetails,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...state.paymentEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              return _PaymentEntryRow(
                key: ValueKey(index),
                index: index,
                payment: payment,
                paymentModes: state.paymentModes,
                l10n: l10n,
              );
            }),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: state.remainingAmount > 0
                  ? () => ref.read(estimateProvider.notifier).addPaymentEntry()
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addPayment),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.total}:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      Text('Rs. ${state.netTotal.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.paid}:', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                      Text('Rs. ${state.totalPaidAmount.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${l10n.remaining}:', style: theme.textTheme.bodyMedium?.copyWith(
                        color: state.remainingAmount > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )),
                      Text('Rs. ${state.remainingAmount.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(
                        color: state.remainingAmount > 0 ? theme.colorScheme.error : theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final s = ref.read(estimateProvider);
                final hasUnsetPaymode=s.paymentEntries.any((e)=>e.paymentModeId == null || e.paymentModeId!.isEmpty);
                if (hasUnsetPaymode) {
                ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!.pleaseEnterPaymode),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
               );
               } else {
                  Navigator.of(context).pop();
               }
              },
              child: Text(l10n.done),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
