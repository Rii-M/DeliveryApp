import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_prefetch_service.dart';
import '../../../models/category.dart';
import '../../../models/rejected_customer.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/dashboard_repository.dart';

class DashboardState {
  final String driverName;
  final List<Category> categories;
  final int todaysDeliveries;
  final int estimatedBills;
  final int todaysSalesReturns;
  final int pendingSync;
  final int assignedCustomersCount;
  final int assignedProductsCount;
  final List<Map<String, dynamic>> remainingStock;
  final List<Map<String, dynamic>> customerSyncStatus;
  final List<RejectedCustomer> rejectedCustomers;
  final String? lastSyncTime;
  final bool isLoading;

  DashboardState({
    this.driverName = 'Ram Sharma',
    this.categories = const [],
    this.todaysDeliveries = 0,
    this.estimatedBills = 0,
    this.todaysSalesReturns = 0,
    this.pendingSync = 0,
    this.assignedCustomersCount = 0,
    this.assignedProductsCount = 0,
    this.remainingStock = const [],
    this.customerSyncStatus = const [],
    this.rejectedCustomers = const [],
    this.lastSyncTime,
    this.isLoading = false,
  });
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(
    dashboardRepo: ref.read(dashboardRepositoryProvider),
    categoryRepo: ref.read(categoryRepositoryProvider),
  );
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _dashboardRepo;
  final CategoryRepository _categoryRepo;

  DashboardNotifier({
    required this._dashboardRepo,
    required CategoryRepository categoryRepo,
  })  : _categoryRepo = categoryRepo,
        super(DashboardState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final cachedCategories = await _categoryRepo.getCachedCategories();
    final hasCache = cachedCategories.isNotEmpty;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final deliveries = await _dashboardRepo.getTodaysDeliveries();
    final estimates = await _dashboardRepo.getEstimatedBillsCreated();
    final salesReturns = await _dashboardRepo.getTodaysSalesReturns();
    final assignedCustomers = await _dashboardRepo.getAssignedCustomersCount();
    final assignedProducts = await _dashboardRepo.getAssignedProductsCount();
    final pendingSync = await _dashboardRepo.getPendingSyncCount();
    final dbLastSync = await _dashboardRepo.getLastSyncTime();
    final customerSyncStatus =
        await _dashboardRepo.getCustomerSyncStatus();
    final rejectedCustomers =
        await _dashboardRepo.getRejectedCustomers(from: startOfDay);

    state = DashboardState(
      isLoading: !hasCache,
      categories: cachedCategories,
      todaysDeliveries: deliveries,
      estimatedBills: estimates,
      todaysSalesReturns: salesReturns,
      pendingSync: pendingSync,
      assignedCustomersCount: assignedCustomers,
      assignedProductsCount: assignedProducts,
      customerSyncStatus: customerSyncStatus,
      rejectedCustomers: rejectedCustomers,
      lastSyncTime: dbLastSync?.toIso8601String(),
    );

    _prefetchImages(cachedCategories);
    _refreshInBackground();
  }

  Future<void> _refreshInBackground() async {
    try {
      final categories = await _categoryRepo.getCachedCategories();
      _prefetchImages(categories);

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final deliveries = await _dashboardRepo.getTodaysDeliveries();
      final estimates = await _dashboardRepo.getEstimatedBillsCreated();
      final salesReturns = await _dashboardRepo.getTodaysSalesReturns();
      final assignedCustomers = await _dashboardRepo.getAssignedCustomersCount();
      final assignedProductCount = await _dashboardRepo.getAssignedProductsCount();
      final remainingStock = await _dashboardRepo.getRemainingAssignedStock();
      final pendingSync = await _dashboardRepo.getPendingSyncCount();
      final dbLastSync = await _dashboardRepo.getLastSyncTime();
      final customerSyncStatus =
          await _dashboardRepo.getCustomerSyncStatus();
      final rejectedCustomers =
          await _dashboardRepo.getRejectedCustomers(from: startOfDay);

      state = DashboardState(
        categories: categories,
        todaysDeliveries: deliveries,
        estimatedBills: estimates,
        todaysSalesReturns: salesReturns,
        pendingSync: pendingSync,
        assignedCustomersCount: assignedCustomers,
        assignedProductsCount: assignedProductCount,
        remainingStock: remainingStock,
        customerSyncStatus: customerSyncStatus,
        rejectedCustomers: rejectedCustomers,
        lastSyncTime: dbLastSync?.toIso8601String(),
      );
    } catch (_) {
      state = DashboardState(
        driverName: state.driverName,
        categories: state.categories,
        todaysDeliveries: state.todaysDeliveries,
        estimatedBills: state.estimatedBills,
        todaysSalesReturns: state.todaysSalesReturns,
        pendingSync: state.pendingSync,
        assignedCustomersCount: state.assignedCustomersCount,
        assignedProductsCount: state.assignedProductsCount,
        remainingStock: state.remainingStock,
        customerSyncStatus: state.customerSyncStatus,
        rejectedCustomers: state.rejectedCustomers,
        lastSyncTime: state.lastSyncTime,
        isLoading: false,
      );
    }
  }

  void _prefetchImages(List<Category> categories) {
    final urls = categories
        .where((c) => c.firstImageUrl != null && c.firstImageUrl!.isNotEmpty)
        .map((c) => c.firstImageUrl!)
        .toList();
    if (urls.isNotEmpty) {
      ImagePrefetchService().prefetchImages(urls);
    }
  }

  Future<void> refresh() async {
    state = DashboardState(isLoading: true, categories: state.categories);
    await _refreshInBackground();
  }
}
