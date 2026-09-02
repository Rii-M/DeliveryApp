import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/customer_picker_sheet.dart';
import '../../../features/sync/provider/sync_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../provider/sales_return_provider.dart';

class SalesReturnScreen extends ConsumerStatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  ConsumerState<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends ConsumerState<SalesReturnScreen> {
  bool _customerPickerOpen = false;
  bool _autoOpenScheduled = false;

  void _openCustomerPicker() {
    if (_customerPickerOpen) return;
    setState(() => _customerPickerOpen = true);
    ref.read(salesReturnProvider.notifier).refreshCustomersFromCache();
  }

  void _closeCustomerPicker() {
    if (!_customerPickerOpen) return;
    setState(() => _customerPickerOpen = false);
  }

  void _handleCustomerSelected(Customer customer) {
    setState(() => _customerPickerOpen = false);
    ref.read(salesReturnProvider.notifier).selectCustomer(customer);
  }

  Future<void> _handleAddCustomer() async {
    final added = await context.push<bool>('/add-customer');
    if (added == true && mounted) {
      ref.read(salesReturnProvider.notifier).refreshCustomersFromCache();
    }
  }

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (ref.read(salesReturnProvider).saved) {
      ref.read(salesReturnProvider.notifier).reset();
    }
  });
}

  Widget _buildCustomerPickerOverlay() {
    final state = ref.read(salesReturnProvider);
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
    final state = ref.read(salesReturnProvider);
    final itemCount = state.items.length;

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
      ref.read(salesReturnProvider.notifier).clearItems();
    }

    _openCustomerPicker();
  }

  Widget _buildAppBarTitle(SalesReturnState state, ThemeData theme) {
    final customer = state.selectedCustomer;
    final appLocalizations = AppLocalizations.of(context)!;
    if (customer == null) {
      return Text(appLocalizations.salesReturn);
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
    final state = ref.watch(salesReturnProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;

    ref.listen<SyncState>(syncProvider, (prev, next) {
      final wasSyncing = prev?.isSyncing ?? false;
      if (wasSyncing && !next.isSyncing) {
        ref.read(salesReturnProvider.notifier).refreshAllFromCache();
      }
    });

    if (!state.isLoading &&
        !state.saved &&
        state.selectedCustomer == null &&
        !_customerPickerOpen &&
        !_autoOpenScheduled) {
      _autoOpenScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoOpenScheduled = false;
        if (mounted && !_customerPickerOpen) {
          _openCustomerPicker();
        }
      });
    }

    final totalQty = state.items.fold<double>(0, (sum, i) => sum + i.quantity);

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                FloatingAppBar(
                  title: _buildAppBarTitle(state, theme),
                  actions: [
                    if (state.items.isNotEmpty)
                      IconButton(
                        icon: Badge(
                          label: Text(totalQty.toStringAsFixed(0)),
                          isLabelVisible: true,
                          child: Icon(Icons.shopping_cart_outlined, size: 28),
                        ),
                        onPressed: () => _openCart(context),
                      ),
                  ],
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.saved
                      ? _buildSuccessState(theme, l10n)
                      : _buildProductBrowser(state, theme, l10n, langCode),
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

  Widget _buildSuccessState(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(l10n.salesReturnSaved, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            l10n.successfullyRecorded,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(salesReturnProvider.notifier).reset();
            },
            child: Text(l10n.newSalesReturn),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () 
            {
              final customer = ref.read(salesReturnProvider).selectedCustomer;
              ref.read(salesReturnProvider.notifier).reset();
              if (customer != null) {
                context.go('/delivery?customerId=${customer.serverId}');
              } else {
                context.go('/delivery');
              }
            },
            child: Text(l10n.goToDelivery),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBrowser(
    SalesReturnState state,
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
            // Commented out: category filter clear button disabled for now.
            // if (state.selectedCategory != null)
            //   TextButton.icon(
            //     onPressed: () => ref
            //         .read(salesReturnProvider.notifier)
            //         .selectCategory(null),
            //     icon: const Icon(Icons.clear, size: 16),
            //     label: Text(l10n.clearFilter),
            //   ),
          ],
        ),
        // Commented out: category filter chips disabled for now.
        // const SizedBox(height: 8),
        // SizedBox(
        //   height: 50,
        //   child: ListView.separated(
        //     scrollDirection: Axis.horizontal,
        //     itemCount: state.categories.length + 1,
        //     separatorBuilder: (_, _) => const SizedBox(width: 8),
        //     itemBuilder: (context, index) {
        //       if (index == 0) {
        //         final isSelected = state.selectedCategory == null;
        //         return FilterChip(
        //           label: Text(l10n.all),
        //           selected: isSelected,
        //           onSelected: (_) => ref
        //               .read(salesReturnProvider.notifier)
        //               .selectCategory(null),
        //         );
        //       }
        //       final cat = state.categories[index - 1];
        //       final isSelected =
        //           state.selectedCategory?.serverId == cat.serverId;
        //       return FilterChip(
        //         avatar: cat.firstImageUrl != null
        //             ? ClipOval(
        //                 child: CachedNetworkImage(
        //                   imageUrl: cat.firstImageUrl!,
        //                   width: 24,
        //                   height: 24,
        //                   fit: BoxFit.cover,
        //                   placeholder: (_, __) => const SizedBox.shrink(),
        //                   errorWidget: (_, __, ___) => const SizedBox.shrink(),
        //                 ),
        //               )
        //             : null,
        //         label: Text(cat.localizedName(langCode)),
        //         selected: isSelected,
        //         onSelected: (_) => ref
        //             .read(salesReturnProvider.notifier)
        //             .selectCategory(isSelected ? null : cat),
        //       );
        //     },
        //   ),
        // ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchProducts,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: state.productSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => ref
                        .read(salesReturnProvider.notifier)
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
              .read(salesReturnProvider.notifier)
              .setProductSearchQuery(value),
        ),
        const SizedBox(height: 12),
        _buildProductGrid(state, theme, l10n, langCode),
      ],
    );
    return AbsorbPointer(
      absorbing: !hasCustomer,
      child: Opacity(opacity: hasCustomer ? 1 : 0.5, child: list),
    );
  }

  Widget _buildProductGrid(
    SalesReturnState state,
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
        final product = products[index];
        final inCart = state.itemQuantityOf(product.serverId);

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
                      product.firstImageUrl != null &&
                          product.firstImageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.firstImageUrl!,
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
                      product.localizedName(langCode),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${product.unitPrice.toStringAsFixed(2)}/${product.unit ?? 'unit'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          ref
                              .read(salesReturnProvider.notifier)
                              .addProduct(product, languageCode: langCode);
                        },
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
    await GoRouter.of(context).push('/sales-return/cart');
  }
}
