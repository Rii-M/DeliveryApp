import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_prefetch_service.dart';
import '../../../models/category.dart';
import '../../../models/customer.dart';
import '../../../models/delivery.dart';
import '../../../models/payment_mode.dart';
import '../../../models/product.dart';
import '../../../models/product_unit.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/delivery_repository.dart';
import '../../../repositories/estimate_repository.dart';
import '../../../repositories/payment_mode_repository.dart';
import '../../../repositories/product_repository.dart';
import '../../../models/payment_entry.dart';

class DeliveryFormState {
  final Delivery? delivery;
  final Category? selectedCategory;
  final List<Category> categories;
  final List<Product> products;
  final List<PaymentMode> paymentModes;
  final PaymentMode? selectedPaymentMode;
  final Map<String, double> cart;
  final Map<String, double> customPrices;
  final Map<String, double> productDiscounts;
  final Map<String, String> selectedUnitIds;
  final Customer? selectedCustomer;
  final List<Customer> customers;
  final String? customerName;
  final String productSearchQuery;
  final int? editingDeliveryId;
  final bool isReadOnly;
  final bool isLoadingCustomers;
  final bool isLoadingProducts;
  final bool isSaving;
  final String? stockError;
  final double paidAmount;
  final List<PaymentEntry> paymentEntries;
  final String? discountType;
  final double discountValue;
  final double discountAmount;

  DeliveryFormState({
    this.delivery,
    this.selectedCategory,
    this.categories = const [],
    this.products = const [],
    this.paymentModes = const [],
    this.selectedPaymentMode,
    this.cart = const {},
    this.customPrices = const {},
    this.productDiscounts = const {},
    this.selectedUnitIds = const {},
    this.selectedCustomer,
    this.customers = const [],
    this.customerName,
    this.productSearchQuery = '',
    this.editingDeliveryId,
    this.isReadOnly = false,
    this.isLoadingCustomers = false,
    this.isLoadingProducts = false,
    this.isSaving = false,
    this.stockError,
    this.paidAmount = 0,
    this.paymentEntries = const [],
    this.discountType,
    this.discountValue = 0,
    this.discountAmount = 0,
  });

  List<Product> get displayedProducts {
    if (selectedCategory == null) return products;
    return products
        .where((p) => p.categoryId == selectedCategory!.serverId)
        .toList();
  }

  List<Product> get filteredProducts {
    if (productSearchQuery.isEmpty) return displayedProducts.take(6).toList();
    final query = productSearchQuery.toLowerCase();
    return products.where((p) => p.name.toLowerCase().contains(query)).toList();
  }

  bool get isValid => cart.values.any((q) => q > 0);

  double getUnitPrice(String productId) {
    if (customPrices.containsKey(productId)) return customPrices[productId]!;
    final product = products.where((p) => p.serverId == productId).firstOrNull;
    return product?.unitPrice ?? 0;
  }

  double get estimatedTotal {
    double total = 0;
    for (final entry in cart.entries) {
      final price = getUnitPrice(entry.key);
      final gross = price * entry.value;
      final discount = productDiscounts[entry.key] ?? 0;
      total += gross - discount;
    }
    return total - discountAmount;
  }

  double getRemainingQuantity(String productId) {
    return products.where((p) => p.serverId == productId).firstOrNull?.stock ??
        0;
  }

  List<ProductUnit> getProductUnits(String productId) {
    final product = products.where((p) => p.serverId == productId).firstOrNull;
    if (product == null) return [];
    final allUnits = <ProductUnit>[];
    final seen = <String>{};
    void addUnit(ProductUnit u) {
      if (u.unitId.isEmpty) return;
      if (seen.add(u.unitId)) allUnits.add(u);
    }

    if (product.unitId != null && product.unitId!.isNotEmpty) {
      addUnit(
        ProductUnit(
          unitId: product.unitId!,
          unitName: product.unit ?? product.unitId!,
        ),
      );
    }
    for (final u in product.units) {
      addUnit(u);
    }
    return allUnits;
  }

  String? getSelectedUnitName(String productId) {
    final unitId = selectedUnitIds[productId];
    if (unitId == null) {
      final product = products
          .where((p) => p.serverId == productId)
          .firstOrNull;
      return product?.unit;
    }
    final product = products.where((p) => p.serverId == productId).firstOrNull;
    if (product == null) return null;
    return product.units.where((u) => u.unitId == unitId).firstOrNull?.unitName;
  }

  String? getSelectedUnitId(String productId) {
    final stored = selectedUnitIds[productId];
    if (stored != null) return stored;
    final product = products.where((p) => p.serverId == productId).firstOrNull;
    return product?.unitId;
  }
}

final deliveryFormProvider =
    StateNotifierProvider<DeliveryFormNotifier, DeliveryFormState>((ref) {
      return DeliveryFormNotifier(
        categoryRepo: ref.read(categoryRepositoryProvider),
        productRepo: ref.read(productRepositoryProvider),
        paymentModeRepo: ref.read(paymentModeRepositoryProvider),
        deliveryRepo: ref.read(deliveryRepositoryProvider),
        estimateRepo: ref.read(estimateRepositoryProvider),
        customerRepo: ref.read(customerRepositoryProvider),
      );
    });

class DeliveryFormNotifier extends StateNotifier<DeliveryFormState> {
  final CategoryRepository _categoryRepo;
  final ProductRepository _productRepo;
  final PaymentModeRepository _paymentModeRepo;
  final DeliveryRepository _deliveryRepo;
  final EstimateRepository _estimateRepo;
  final CustomerRepository _customerRepo;

  DeliveryFormNotifier({
    required this._categoryRepo,
    required ProductRepository productRepo,
    required this._paymentModeRepo,
    required this._deliveryRepo,
    required this._estimateRepo,
    required this._customerRepo,
  }) : _productRepo = productRepo,
       super(DeliveryFormState()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    state = DeliveryFormState(isLoadingCustomers: true);

    try {
      final categories = await _categoryRepo.getCachedCategories();
      final products = await _loadAllProducts();
      final paymentModes = await _loadAllPaymentModes();
      final customers = await _customerRepo.getCachedCustomers();

      _prefetchProductImages(products);

      state = DeliveryFormState(
        categories: categories,
        products: products,
        paymentModes: paymentModes,
        customers: customers,
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    } catch (_) {
      state = DeliveryFormState(
        categories: await _categoryRepo.getCachedCategories(),
        products: await _loadAllProducts(),
        paymentModes: await _loadAllPaymentModes(),
        customers: await _customerRepo.getCachedCustomers(),
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    }
  }

  Future<List<Product>> _loadAllProducts() async {
    try {
      return await _productRepo.getCachedProducts();
    } catch (_) {
      return [];
    }
  }

  Future<List<PaymentMode>> _loadAllPaymentModes() async {
    try {
      return await _paymentModeRepo.getPaymentModes();
    } catch (_) {
      return [];
    }
  }

  Future<void> refreshProducts() async {
    final products = await _loadAllProducts();
    if (products.isNotEmpty) {
      _prefetchProductImages(products);
    }
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: products,
      paymentModes: state.paymentModes,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      customerName: state.customerName,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
      productSearchQuery: state.productSearchQuery,
      editingDeliveryId: state.editingDeliveryId,
      isReadOnly: state.isReadOnly,
      isLoadingCustomers: false,
      isLoadingProducts: false,
      isSaving: state.isSaving,
      paidAmount: state.paidAmount,
      paymentEntries: state.paymentEntries,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void _prefetchProductImages(List<Product> products) {
    final urls = products
        .where((p) => p.firstImageUrl != null && p.firstImageUrl!.isNotEmpty)
        .map((p) => p.firstImageUrl!)
        .toList();
    if (urls.isNotEmpty) {
      ImagePrefetchService().prefetchImages(urls);
    }
  }

  Future<void> refreshCustomersFromCache() async {
    try {
      final customers = await _customerRepo.getCachedCustomers();
      if (!mounted) return;
      state = DeliveryFormState(
        delivery: state.delivery,
        selectedCategory: state.selectedCategory,
        categories: state.categories,
        products: state.products,
        paymentModes: state.paymentModes,
        paymentEntries: state.paymentEntries,
        selectedPaymentMode: state.selectedPaymentMode,
        cart: state.cart,
        customPrices: state.customPrices,
        productDiscounts: state.productDiscounts,
        selectedUnitIds: state.selectedUnitIds,
        productSearchQuery: state.productSearchQuery,
        selectedCustomer: state.selectedCustomer,
        customers: customers,
        customerName: state.customerName,
        editingDeliveryId: state.editingDeliveryId,
        isReadOnly: state.isReadOnly,
        paidAmount: state.paidAmount,
        discountType: state.discountType,
        discountValue: state.discountValue,
        discountAmount: state.discountAmount,
      );
    } catch (e) {
      print('[Delivery] customer refresh failed: $e');
    }
  }

  Future<void> loadExistingDelivery(int deliveryId) async {
    state = DeliveryFormState(isLoadingCustomers: true);

    try {
      final delivery = await _deliveryRepo.getDeliveryById(deliveryId);
      if (delivery == null) {
        state = DeliveryFormState();
        return;
      }

      final products = await _loadAllProducts();
      final categories = await _categoryRepo.getCachedCategories();
      final paymentModes = await _loadAllPaymentModes();
      final items = await _deliveryRepo.getDeliveryItems(deliveryId);

      List<Customer> loadedCustomers = const [];
      Customer? selectedCustomer;
      if (delivery.customerId.isNotEmpty) {
        try {
          loadedCustomers = await _customerRepo.getCachedCustomers();
          selectedCustomer = loadedCustomers.cast<Customer?>().firstWhere(
            (c) => c?.serverId == delivery.customerId,
            orElse: () => null,
          );
        } catch (_) {}
      }

      final selectedPaymentMode = paymentModes.cast<PaymentMode?>().firstWhere(
        (m) => m?.serverId == delivery.paymentMode,
        orElse: () => null,
      );

      final cart = <String, double>{};
      final customPrices = <String, double>{};
      final selectedUnitIds = <String, String>{};
      for (final item in items) {
        cart[item.productId] = (cart[item.productId] ?? 0) + item.quantity;
        if (item.unitPrice > 0) {
          customPrices[item.productId] = item.unitPrice;
        }
        final product = products
            .where((p) => p.serverId == item.productId)
            .firstOrNull;
        if (item.unitId != null &&
            product != null &&
            item.unitId != product.unitId) {
          selectedUnitIds[item.productId] = item.unitId!;
        }
      }

      final existingEstimates = await _estimateRepo.getEstimatesByDelivery(
        deliveryId,
      );
      final isReadOnly = existingEstimates.isNotEmpty;
      final paidAmount = existingEstimates.isNotEmpty
          ? existingEstimates.first.paidAmount
          : 0.0;
      final paymentEntries = existingEstimates.isNotEmpty
          ? existingEstimates.first.paymentEntries
          : <PaymentEntry>[];

      String? discountType;
      double discountValue = 0;
      double discountAmount = 0;
      final productDiscounts = <String, double>{};
      if (existingEstimates.isNotEmpty) {
        final estimate = existingEstimates.first;
        discountType = estimate.discountType;
        discountValue = estimate.discountValue;
        discountAmount = estimate.discountAmount;
        final estimateItems = await _estimateRepo.getEstimateItems(
          estimate.id!,
        );
        for (final ei in estimateItems) {
          if (ei.discountAmount > 0) {
            productDiscounts[ei.productId] = ei.discountAmount;
          }
        }
      }

      state = DeliveryFormState(
        delivery: delivery,
        isReadOnly: isReadOnly,
        paidAmount: paidAmount,
        paymentEntries: paymentEntries,
        customerName: selectedCustomer?.name,
        customers: loadedCustomers,
        selectedCustomer: selectedCustomer,
        categories: categories,
        products: products,
        paymentModes: paymentModes,
        selectedPaymentMode: selectedPaymentMode,
        customPrices: customPrices,
        productDiscounts: productDiscounts,
        selectedUnitIds: selectedUnitIds,
        cart: cart,
        discountType: discountType,
        discountValue: discountValue,
        discountAmount: discountAmount,
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    } catch (_) {
      state = DeliveryFormState(
        categories: await _categoryRepo.getCachedCategories(),
        products: await _loadAllProducts(),
        paymentModes: await _loadAllPaymentModes(),
        customers: await _customerRepo.getCachedCustomers(),
        isLoadingCustomers: false,
        isLoadingProducts: false,
      );
    }
  }

  void selectCategory(Category? category) {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: category,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      productSearchQuery: '',
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
      customerName: state.customerName,
      editingDeliveryId: state.editingDeliveryId,
      isReadOnly: state.isReadOnly,
    );
  }

  void selectPaymentMode(PaymentMode? mode) {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: mode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
      customerName: state.customerName,
    );
  }

  void selectCustomer(Customer? customer) {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: customer,
      customers: state.customers,
      customerName: customer?.name,
      editingDeliveryId: state.editingDeliveryId,
      isReadOnly: state.isReadOnly,
      paidAmount: state.paidAmount,
      discountType: state.discountType,
      discountValue: state.discountValue,
      discountAmount: state.discountAmount,
    );
  }

  void setCustomPrice(String productId, double price) {
    final updated = Map<String, double>.from(state.customPrices);
    if (price <= 0) {
      updated.remove(productId);
    } else {
      updated[productId] = price;
    }
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: updated,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void setSelectedUnit(String productId, String unitId) {
    final updated = Map<String, String>.from(state.selectedUnitIds);
    final product = state.products
        .where((p) => p.serverId == productId)
        .firstOrNull;
    if (product == null) return;
    final unit = product.units.where((u) => u.unitId == unitId).firstOrNull;
    if (unit == null && unitId != (product.unitId ?? '')) return;
    if (unitId == (product.unitId ?? '')) {
      updated.remove(productId);
    } else {
      updated[productId] = unitId;
    }
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: updated,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void addToCart(String productId, double quantity) {
    if (quantity <= 0) return;
    final currentQty = state.cart[productId] ?? 0;
    final newQty = currentQty + quantity;
    final remaining = state.getRemainingQuantity(productId);
    if (newQty > remaining) {
      state = DeliveryFormState(
        delivery: state.delivery,
        selectedCategory: state.selectedCategory,
        categories: state.categories,
        products: state.products,
        paymentModes: state.paymentModes,
        paymentEntries: state.paymentEntries,
        selectedPaymentMode: state.selectedPaymentMode,
        cart: state.cart,
        customPrices: state.customPrices,
        productDiscounts: state.productDiscounts,
        selectedUnitIds: state.selectedUnitIds,
        productSearchQuery: state.productSearchQuery,
        selectedCustomer: state.selectedCustomer,
        customers: state.customers,
        stockError: 'Entered quantity exceeds today\'s available stock.',
      );
      return;
    }
    final updated = Map<String, double>.from(state.cart);
    updated[productId] = newQty;
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: updated,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void updateCartQuantity(String productId, double quantity) {
    final remaining = state.getRemainingQuantity(productId);
    if (quantity > remaining) {
      state = DeliveryFormState(
        delivery: state.delivery,
        selectedCategory: state.selectedCategory,
        categories: state.categories,
        products: state.products,
        paymentModes: state.paymentModes,
        paymentEntries: state.paymentEntries,
        selectedPaymentMode: state.selectedPaymentMode,
        cart: state.cart,
        customPrices: state.customPrices,
        productDiscounts: state.productDiscounts,
        selectedUnitIds: state.selectedUnitIds,
        productSearchQuery: state.productSearchQuery,
        selectedCustomer: state.selectedCustomer,
        customers: state.customers,
        stockError: 'Entered quantity exceeds today\'s available stock.',
      );
      return;
    }
    final updated = Map<String, double>.from(state.cart);
    if (quantity < 0) {
      updated.remove(productId);
    } else {
      updated[productId] = quantity;
    }
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: updated,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void removeFromCart(String productId) {
    final updated = Map<String, double>.from(state.cart)..remove(productId);
    final updatedDiscounts = Map<String, double>.from(state.productDiscounts)
      ..remove(productId);
    final updatedUnits = Map<String, String>.from(state.selectedUnitIds)
      ..remove(productId);
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: updated,
      customPrices: state.customPrices,
      productDiscounts: updatedDiscounts,
      selectedUnitIds: updatedUnits,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void setProductDiscount(String productId, double amount) {
    final updated = Map<String, double>.from(state.productDiscounts);
    if (amount <= 0) {
      updated.remove(productId);
    } else {
      updated[productId] = amount;
    }
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: updated,
      selectedUnitIds: state.selectedUnitIds,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void clearCart() {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void clearStockError() {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      productSearchQuery: state.productSearchQuery,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void setProductSearchQuery(String query) {
    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      productSearchQuery: query,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
    );
  }

  void resetForm() {
    state = DeliveryFormState(
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      customers: state.customers,
    );
  }

  Future<DeliveryResult> saveDelivery() async {
    if (!state.isValid) return DeliveryResult(success: false);

    state = DeliveryFormState(
      delivery: state.delivery,
      selectedCategory: state.selectedCategory,
      categories: state.categories,
      products: state.products,
      paymentModes: state.paymentModes,
      paymentEntries: state.paymentEntries,
      selectedPaymentMode: state.selectedPaymentMode,
      cart: state.cart,
      customPrices: state.customPrices,
      productDiscounts: state.productDiscounts,
      selectedUnitIds: state.selectedUnitIds,
      selectedCustomer: state.selectedCustomer,
      customers: state.customers,
      isSaving: true,
    );

    try {
      final items = state.cart.entries.map((e) {
        final item = DeliveryItem();
        item.productId = e.key;
        item.quantity = e.value;
        item.unitPrice = state.getUnitPrice(e.key);
        item.unitId = state.getSelectedUnitId(e.key);
        item.unit = state.getSelectedUnitName(e.key);
        return item;
      }).toList();

      Delivery delivery;

      if (state.editingDeliveryId != null) {
        final oldItems = await _deliveryRepo.getDeliveryItems(
          state.editingDeliveryId!,
        );
        for (final oldItem in oldItems) {
          await _productRepo.restoreStock(oldItem.productId, oldItem.quantity);
        }

        delivery = await _deliveryRepo.updateDelivery(
          state.editingDeliveryId!,
          customerId: state.selectedCustomer?.serverId ?? '',
          items: items,
          paymentMode: state.selectedPaymentMode?.serverId,
        );
      } else {
        delivery = await _deliveryRepo.saveDelivery(
          customerId: state.selectedCustomer?.serverId ?? '',
          items: items,
          paymentMode: state.selectedPaymentMode?.serverId,
        );
      }

      for (final entry in state.cart.entries) {
        await _productRepo.deductStock(entry.key, entry.value);
      }

      state = DeliveryFormState(
        categories: state.categories,
        products: state.products,
        paymentModes: state.paymentModes,
        customers: state.customers,
      );

      return DeliveryResult(success: true, deliveryId: delivery.id!);
    } catch (e) {
      state = DeliveryFormState(
        delivery: state.delivery,
        selectedCategory: state.selectedCategory,
        categories: state.categories,
        products: state.products,
        paymentModes: state.paymentModes,
        paymentEntries: state.paymentEntries,
        selectedPaymentMode: state.selectedPaymentMode,
        cart: state.cart,
        customPrices: state.customPrices,
        productDiscounts: state.productDiscounts,
        selectedUnitIds: state.selectedUnitIds,
        selectedCustomer: state.selectedCustomer,
        customers: state.customers,
        isSaving: false,
      );
      return DeliveryResult(success: false, error: e.toString());
    }
  }
}

class DeliveryResult {
  final bool success;
  final int? deliveryId;
  final String? error;

  DeliveryResult({required this.success, this.deliveryId, this.error});
}
