import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/provider/auth_provider.dart';
import '../../features/auth/screen/login_screen.dart';
import '../../features/dashboard/screen/add_customer_screen.dart';
import '../../features/dashboard/screen/categories_screen.dart';
import '../../features/dashboard/screen/customer_sync_status_screen.dart';
import '../../features/dashboard/screen/customers_screen.dart';
import '../../features/dashboard/screen/dashboard_screen.dart';
import '../../features/dashboard/screen/products_screen.dart';
import '../../features/delivery/screen/delivery_history_screen.dart';
import '../../features/delivery/screen/delivery_screen.dart';
import '../../features/estimate/screen/estimate_history_screen.dart';
import '../../features/estimate/screen/estimate_screen.dart';
import '../../features/profile/screen/profile_screen.dart';
import '../../features/sales_return/screen/sales_return_detail_screen.dart';
import '../../features/sales_return/screen/sales_return_history_screen.dart';
import '../../features/sales_return/screen/sales_return_screen.dart';
import '../../features/sync/screen/sync_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';
import '../../features/delivery/screen/cart_screen.dart';
import '../../features/sales_return/screen/sales_return_cart_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.status == AuthStatus.uninitialized) return '/splash';
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/sales-return';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/delivery',
            pageBuilder: (context, state) {
              final deliveryId = int.tryParse(
                state.uri.queryParameters['deliveryId'] ?? '',
              );
              final customerId = state.uri.queryParameters['customerId'];
              return NoTransitionPage(
                child: DeliveryScreen(
                  deliveryId: deliveryId,
                  customerId: customerId,
                ),
              );
            },
          ),
          // GoRoute(
          //   path: '/sales-return',
          //   pageBuilder: (context, state) =>
          //       const NoTransitionPage(child: SalesReturnScreen()),
          // ),
          GoRoute(
             path: '/sales-return',
             pageBuilder: (context, state) =>
                 const NoTransitionPage(child: SalesReturnScreen()),
                 routes: [
                    GoRoute(
                      path: 'cart',
                      builder: (context, state) => const SalesReturnCartScreen(),
                    ),
                  ],
           ),
          GoRoute(
            path: '/sync',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SyncScreen()),
          ),
          GoRoute(
            path: '/delivery-history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DeliveryHistoryScreen()),
          ),
          GoRoute(
            path: '/sales-return-history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesReturnHistoryScreen()),
          ),
          GoRoute(
            path: '/delivery',
            pageBuilder: (context, state) {
              final deliveryId = int.tryParse(
                state.uri.queryParameters['deliveryId'] ?? '',
              );
              final customerId = state.uri.queryParameters['customerId'];
              return NoTransitionPage(
                child: DeliveryScreen(
                  deliveryId: deliveryId,
                  customerId: customerId,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'cart',
                builder: (context, state) => const CartScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/delivery-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final deliveryId = int.tryParse(state.pathParameters['id'] ?? '');
          return DeliveryScreen(deliveryId: deliveryId);
        },
      ),
      GoRoute(
        path: '/sales-return-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final salesReturnId = int.tryParse(state.pathParameters['id'] ?? '');
          return SalesReturnDetailScreen(salesReturnId: salesReturnId!);
        },
      ),
      GoRoute(
        path: '/estimate',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final deliveryId = int.tryParse(
            state.uri.queryParameters['deliveryId'] ?? '',
          );
          return EstimateScreen(deliveryId: deliveryId);
        },
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/estimate-history',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EstimateHistoryScreen(),
      ),
      GoRoute(
        path: '/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: '/products',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProductsScreen(),
      ),
      GoRoute(
        path: '/customers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomersScreen(),
      ),
      GoRoute(
        path: '/customer-sync-status',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CustomerSyncStatusScreen(),
      ),
      GoRoute(
        path: '/add-customer',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AddCustomerScreen(customer: state.extra as Customer?),
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/delivery')) return 1;
    if (location.startsWith('/sales-return')) return 0;
    if (location.startsWith('/sync')) return 2;
    if (location.startsWith('/dashboard')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/sales-return');
      case 1:
        context.go('/delivery');
      case 2:
        context.go('/sync');
      case 3:
        context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.assignment_return_outlined),
            selectedIcon: Icon(Icons.assignment_return),
            label: l10n.salesReturn,
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: l10n.delivery,
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: l10n.sync,
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
        ],
      ),
    );
  }
}
