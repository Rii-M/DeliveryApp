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
import '../../features/sync/provider/sync_provider.dart';
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

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _accentColors = <int, Color>{
    0: Color(0xFFB4482E), // Sales Return — coral
    1: Color(0xFFE2992F), // Delivery — amber
    2: Color(0xFF6B4C7A), // Sync — violet
    3: Color(0xFF4B7A5B), // Dashboard — teal
  };

  static const _indicatorColors = <int, Color>{
    0: Color(0xFFF7E6E1),
    1: Color(0xFFFBEEDA),
    2: Color(0xFFEFE7F2),
    3: Color(0xFFE7F0E9),
  };

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

  Widget _badge({required Widget child, required int pendingCount}) {
    if (pendingCount <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFB4482E),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFFFFFF),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = _currentIndex(context);
    final pendingCount = ref.watch(syncProvider).pendingCount;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  final selected = states.contains(WidgetState.selected);
                  return TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  );
                }),
              ),
            ),
            child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) => _onTap(context, index),
            backgroundColor: colorScheme.surface,
            indicatorColor: _indicatorColors[currentIndex],
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.assignment_return_outlined,
                  color: currentIndex == 0 ? _accentColors[0] : null,
                ),
                selectedIcon: Icon(
                  Icons.assignment_return,
                  color: _accentColors[0],
                ),
                label: l10n.salesReturn,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.local_shipping_outlined,
                  color: currentIndex == 1 ? _accentColors[1] : null,
                ),
                selectedIcon: Icon(
                  Icons.local_shipping,
                  color: _accentColors[1],
                ),
                label: l10n.delivery,
              ),
              NavigationDestination(
                icon: _badge(
                  pendingCount: pendingCount,
                  child: Icon(
                    Icons.sync_outlined,
                    color: currentIndex == 2 ? _accentColors[2] : null,
                  ),
                ),
                selectedIcon: _badge(
                  pendingCount: pendingCount,
                  child: Icon(
                    Icons.sync,
                    color: _accentColors[2],
                  ),
                ),
                label: l10n.sync,
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.dashboard_outlined,
                  color: currentIndex == 3 ? _accentColors[3] : null,
                ),
                selectedIcon: Icon(
                  Icons.dashboard,
                  color: _accentColors[3],
                ),
                label: l10n.dashboard,
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}
