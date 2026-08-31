import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/extensions.dart';
import '../../../core/utils/tax_calculator.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/customer_picker_sheet.dart';
import '../../../features/sync/provider/sync_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../models/cart_item.dart';
import '../provider/delivery_provider.dart';
import 'cart_screen.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  final int? deliveryId;
  final String? customerId;

  const DeliveryScreen({super.key, this.deliveryId, this.customerId});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  bool _customerPickerOpen = false;
  bool _autoOpenScheduled = false;
  bool _preselecting = false;

  @override
  void initState() {
    super.initState();
    final customerId = widget.customerId;
    if (customerId != null) _preselecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deliveryFormProvider.notifier).refreshProducts();
      if (widget.deliveryId != null) {
        ref
            .read(deliveryFormProvider.notifier)
            .loadExistingDelivery(widget.deliveryId!);
      } else if (customerId != null) {
        _preselectCustomer(customerId);
      } else {
        final state = ref.read(deliveryFormProvider);
        if (state.delivery != null) {
          ref.read(deliveryFormProvider.notifier).resetForm();
        } else {
          ref.read(deliveryFormProvider.notifier).clearSelectedCustomer();
        }
      }
    });
  }

  Future<void> _preselectCustomer(String customerId) async {
    await ref.read(deliveryFormProvider.notifier).preselectCustomer(customerId);
    if (mounted) {
      setState(() => _preselecting = false);
      final customer = ref.read(deliveryFormProvider).selectedCustomer;
      if (customer != null) {
        _autoAddCustomerProductsToCart(customer);
      }
    }
  }

  void _openCustomerPicker() {
    if (_customerPickerOpen) return;
    setState(() => _customerPickerOpen = true);
    ref.read(deliveryFormProvider.notifier).refreshCustomersFromCache();
  }

  void _closeCustomerPicker() {
    if (!_customerPickerOpen) return;
    setState(() => _customerPickerOpen = false);
  }

  void _handleCustomerSelected(Customer customer) {
    setState(() => _customerPickerOpen = false);
    ref.read(deliveryFormProvider.notifier).selectCustomer(customer);
    // Auto-add customer's assigned products to cart
    _autoAddCustomerProductsToCart(customer);
  }

  Future<void> _autoAddCustomerProductsToCart(Customer customer) async {
    // Wait a frame for the provider to update products state
    await Future.delayed(const Duration(milliseconds: 100));
    final notifier = ref.read(deliveryFormProvider.notifier);
    final products = notifier.state.products;
    final customerId = customer.serverId;
    
    // Add each product that belongs to this customer to the cart
    for (final product in products) {
      // Filter products assigned to this customer by customer_id
      if (product.customerId == customerId) {
        final key = DeliveryFormState.variantKey(product);
        // Use product's actual stock/quantity from API instead of hardcoded 1
        final double quantityToAdd = product.stock > 0 ? product.stock : 1;
        print('[DELIVERY_SCREEN] Adding to cart: ${product.name}, stock: ${product.stock}, qty: $quantityToAdd');
        await notifier.addToCart(key, quantityToAdd);
      }
    }
    print('[DELIVERY_SCREEN] Auto-add complete');
  }

  Future<void> _handleAddCustomer() async {
    final added = await context.push<bool>('/add-customer');
    if (added == true && mounted) {
      ref.read(deliveryFormProvider.notifier).refreshCustomersFromCache();
    }
  }

  Widget _buildCustomerPickerOverlay() {
    final state = ref.read(deliveryFormProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _closeCustomerPicker,
      child: ColoredBox(
        color: Colors.black54,
        child: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: CustomerPickerSheet(
                customers: state.customers,
                selectedCustomer: state.selectedCustomer,
                onCustomerSelected: _handleCustomerSelected,
                onAddCustomer: _handleAddCustomer,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTitleTap() async {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.read(deliveryFormProvider);
    final itemCount = state.cart.values.fold<int>(
      0,
      (sum, q) => sum + q.toInt(),
    );

    if (itemCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.changeCustomerTitle),
          content: Text(l10n.changeCustomerMessage(itemCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.clearAndContinue),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      ref.read(deliveryFormProvider.notifier).clearCart();
    }

    _openCustomerPicker();
  }

  Widget _buildAppBarTitle(DeliveryFormState state, ThemeData theme) {
    final appLocalizations = AppLocalizations.of(context)!;
    if (state.isReadOnly) {
      return Text(
        appLocalizations.deliveryNumber(widget.deliveryId.toString()),
      );
    }
    final customer = state.selectedCustomer;
    if (customer == null) {
      return Text(appLocalizations.addProducts);
    }
    return InkWell(
      onTap: _handleTitleTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                customer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _customerPickerOpen ? theme.colorScheme.primary : null,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              _customerPickerOpen
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              size: 22,
              color: _customerPickerOpen ? theme.colorScheme.primary : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      );
    }).toList();

    ref.listen<SyncState>(syncProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;
      if (wasSyncing && !next.isSyncing) {
        ref.read(deliveryFormProvider.notifier).refreshCustomersFromCache();
        ref.read(deliveryFormProvider.notifier).refreshCategoriesFromCache();
      }
    });

    if (!state.isLoadingCustomers &&
        !state.isReadOnly &&
        state.selectedCustomer == null &&
        !_customerPickerOpen &&
        !_autoOpenScheduled &&
        !_preselecting) {
      _autoOpenScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoOpenScheduled = false;
        if (mounted && !_customerPickerOpen) {
          _openCustomerPicker();
        }
      });
    }

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                FloatingAppBar(
                  title: _buildAppBarTitle(state, theme),
                  actions: [
                    if (!state.isReadOnly && state.cart.isNotEmpty)
                      IconButton(
                        icon: Badge(
                          label: Text(
                            '${cartItems.fold<int>(0, (sum, item) => sum + item.quantity.toInt())}',
                          ),
                          isLabelVisible: true,
                          child: Icon(Icons.shopping_cart_outlined, size: 28),
                        ),
                        onPressed: () => _openCart(context),
                      ),
                  ],
                ),
                Expanded(
                  child: state.isLoadingCustomers
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(state, cartItems, theme, l10n, langCode),
                ),
              ],
            ),
          ),
        ),
        if (_customerPickerOpen)
          Positioned.fill(child: _buildCustomerPickerOverlay()),
      ],
    );
  }

  Widget _buildBody(
    DeliveryFormState state,
    List<CartItem> cartItems,
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
  ) {
    if (state.isReadOnly) {
      return _buildReadOnlyView(state, cartItems, theme, l10n);
    }
    return _buildEditableForm(state, cartItems, theme, l10n, langCode);
  }

  Widget _buildReadOnlyView(
    DeliveryFormState state,
    List<CartItem> cartItems,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final delivery = state.delivery;

    final itemsWithTax = cartItems.map((item) {
      final product = state.products
          .where((p) => p.serverId == item.productId)
          .firstOrNull;
      final tax = computeItemTax(
        rate: item.unitPrice,
        quantity: item.quantity,
        discount: item.discountAmount,
        taxableType: product?.taxable ?? 0,
      );
      return (item: item, tax: tax);
    }).toList();

    final totalGrossIncTax = itemsWithTax.fold<double>(
      0,
      (sum, e) => sum + e.tax.grossAmountIncTax,
    );
    final totalDiscountIncTax = itemsWithTax.fold<double>(
      0,
      (sum, e) => sum + e.tax.discountIncludingTax,
    );
    final totalTax = itemsWithTax.fold<double>(
      0,
      (sum, e) => sum + e.tax.taxAmount,
    );
    final globalDiscountIncTax = state.discountAmount > 0
        ? state.discountAmount
        : 0.0;
    final netTotal =
        totalGrossIncTax - totalDiscountIncTax - globalDiscountIncTax;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.visibility,
                color: theme.colorScheme.onTertiaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.viewingCompletedInvoice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.invoiceNumber(delivery?.id.toString() ?? ''),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (delivery?.createdDate != null)
                      Text(
                        delivery!.createdDate.formattedDateTime,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                if (state.customerName != null) ...[
                  Text(
                    l10n.customer,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(state.customerName!, style: theme.textTheme.bodyMedium),
                ],
                if (state.paymentEntries.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.paymentMode,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...state.paymentEntries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${e.paymentModeName ?? 'Cash'} - Rs. ${e.amount.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.items,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...itemsWithTax.map(
          (e) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.item.productName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.qtyWithPrice(
                            e.tax.rateIncTax.toStringAsFixed(2),
                            e.item.quantity.toStringAsFixed(0),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (e.item.discountAmount > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Discount: -Rs. ${e.item.discountAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    'Rs. ${e.tax.netAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      'Rs. ${totalGrossIncTax.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (totalDiscountIncTax > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.productDiscount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      Text(
                        '- Rs. ${totalDiscountIncTax.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (globalDiscountIncTax > 0) ...[
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
                        '- Rs. ${globalDiscountIncTax.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (totalTax > 0) ...[
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
                        'Rs. ${totalTax.toStringAsFixed(2)}',
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
                      'Rs. ${netTotal.toStringAsFixed(2)}',
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
      ],
    );
  }

  Widget _buildEditableForm(
    DeliveryFormState state,
    List<CartItem> cartItems,
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
  ) {
    final hasCustomer = state.selectedCustomer != null;
    final list = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Text(
              l10n.products,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (state.selectedCategory != null)
              TextButton.icon(
                onPressed: () => ref
                    .read(deliveryFormProvider.notifier)
                    .selectCategory(null),
                icon: const Icon(Icons.clear, size: 16),
                label: Text(l10n.clearFilter),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.categories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = state.selectedCategory == null;
                return FilterChip(
                  label: Text(l10n.all),
                  selected: isSelected,
                  onSelected: (_) => ref
                      .read(deliveryFormProvider.notifier)
                      .selectCategory(null),
                );
              }
              final cat = state.categories[index - 1];
              final isSelected =
                  state.selectedCategory?.serverId == cat.serverId;
              return FilterChip(
                avatar: cat.firstImageUrl != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: cat.firstImageUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const SizedBox.shrink(),
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      )
                    : null,
                label: Text(cat.localizedName(langCode)),
                selected: isSelected,
                onSelected: (_) => ref
                    .read(deliveryFormProvider.notifier)
                    .selectCategory(isSelected ? null : cat),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchProducts,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(deliveryFormProvider.notifier)
                        .setProductSearchQuery(''),
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) => ref
              .read(deliveryFormProvider.notifier)
              .setProductSearchQuery(value),
        ),
        const SizedBox(height: 12),
        if (state.stockError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.stockError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () =>
                      ref.read(deliveryFormProvider.notifier).clearStockError(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (state.isLoadingProducts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else
          _buildProductGrid(context, ref, state, theme, l10n, langCode),
      ],
    );
    return AbsorbPointer(
      absorbing: !hasCustomer,
      child: Opacity(opacity: hasCustomer ? 1 : 0.5, child: list),
    );
  }

  Widget _buildProductGrid(
    BuildContext context,
    WidgetRef ref,
    DeliveryFormState state,
    ThemeData theme,
    AppLocalizations l10n,
    String langCode,
  ) {
    final products = state.filteredProducts;
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              state.selectedCategory != null
                  ? l10n.noProductsInCategory
                  : l10n.selectCategoryToBrowse,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.5,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final card = products[index];
        // Resolve all underlying variants that merge into this display card
        // (same product+rate+unit, possibly across chalans/customers).
        final dKey = DeliveryFormState.displayKey(card);
        final variantKeys = state.products
            .where((p) => DeliveryFormState.displayKey(p) == dKey)
            .map((p) => DeliveryFormState.variantKey(p))
            .toList();
        final inCart = variantKeys.fold<double>(
            0.0, (sum, k) => sum + (state.cart[k] ?? 0));
        final remaining = variantKeys.fold<double>(
            0.0, (sum, k) => sum + state.getRemainingQuantity(k));

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  height: 140,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child:
                      card.firstImageUrl != null &&
                          card.firstImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: card.firstImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              _buildShimmerPlaceholder(theme),
                          errorWidget: (_, _, _) =>
                              _buildPlaceholderIcon(theme),
                        )
                      : _buildPlaceholderIcon(theme),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.localizedName(langCode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${card.unitPrice.toStringAsFixed(0)}/${card.unit ?? 'unit'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.available} ${remaining.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: remaining > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: remaining > 0
                            ? () {
                                final notifier = ref.read(
                                  deliveryFormProvider.notifier,
                                );
                                for (final k in variantKeys) {
                                  notifier.addToCart(k, 1);
                                }
                              }
                            : null,
                        icon: Icon(
                          inCart > 0
                              ? Icons.check_circle
                              : Icons.add_shopping_cart,
                          size: 16,
                        ),
                        label: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 24),
                          child: Text(
                            inCart > 0 ? l10n.addMore : l10n.add,
                            softWrap: false,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                    if (inCart > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${l10n.inCart} ${inCart.toStringAsFixed(0)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon(ThemeData theme) {
    return Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 40,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
      ),
    );
  }

  void _openCart(BuildContext context) async {
    final continueToBilling = await GoRouter.of(
      context,
    ).push<bool>('/delivery/cart');
    if (continueToBilling == true && context.mounted) {
      _continueToBilling(context);
    }
  }

  Future<void> _continueToBilling(BuildContext context) async {
    if (!ref.read(deliveryFormProvider).isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseSelectItems),
        ),
      );
      return;
    }
    GoRouter.of(context).push('/estimate');
  }
}
