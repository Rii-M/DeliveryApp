import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../auth/provider/auth_provider.dart';
import '../../sync/provider/sync_provider.dart';
import '../provider/dashboard_provider.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/stat_card.dart';
import '../../location/location_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final locationState = ref.watch(locationStateProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // Reload the dashboard (incl. customer sync status) whenever a sync run
    // finishes so the box at the bottom reflects synced / not-synced results.
    ref.listen(syncProvider, (previous, next) {
      final wasSyncing = previous?.isSyncing ?? false;
      final inSyncing = next.isSyncing;
      if (wasSyncing && !inSyncing) {
        ref.read(dashboardProvider.notifier).loadDashboard();
      }
    });

    final displayName = authState.userName ?? state.driverName;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 0,
        leading: Padding(
          padding: EdgeInsets.all(8),
          child: Image.asset('assets/icon/logo.png', fit: BoxFit.contain),
        ),
        title:Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.welcomeBack,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
         ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              locationState.isOnline ? Icons.cloud_done : Icons.cloud_off,
              color: locationState.isOnline ? Colors.green : Colors.red,
            ),
            tooltip: locationState.isOnline ? l10n.online : l10n.offline,
            onPressed: () =>
                ref.read(locationStateProvider.notifier).manualSync(),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).loadDashboard(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildLocationTrackingSection(locationState, theme, l10n),
            const SizedBox(height: 20),
            Text(
              l10n.quickActions,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActions(context, l10n),
            const SizedBox(height: 20),
            _buildStatsRow(state, theme, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrackingSection(
    LocationState locationState,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: locationState.isTracking
                    ? (isDark ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50)
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: locationState.isTracking
                      ? (isDark ? Colors.green.shade700 : Colors.green.shade200)
                      : theme.colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    locationState.isTracking
                        ? Icons.track_changes
                        : Icons.location_off,
                    color: locationState.isTracking
                        ? Colors.green
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locationState.isTracking
                          ? l10n.yourLocationIsBeingTracked
                          : l10n.pleaseStartDuty,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: locationState.isTracking
                            ? (isDark ? Colors.green.shade200 : Colors.green.shade700)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (locationState.pendingSyncCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.orange.shade900.withValues(alpha: 0.3) : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.countPending(
                          locationState.pendingSyncCount.toString(),
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.orange.shade200 : Colors.orange.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: locationState.isTracking
                        ? null
                        : () => ref
                              .read(locationStateProvider.notifier)
                              .startTracking(),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.startDuty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: locationState.isTracking
                        ? () => ref
                              .read(locationStateProvider.notifier)
                              .stopTracking()
                        : null,
                    icon: const Icon(Icons.stop, size: 18),
                    label: Text(l10n.stopDuty),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: locationState.pendingSyncCount > 0
                    ? () =>
                          ref.read(locationStateProvider.notifier).manualSync()
                    : null,
                icon: const Icon(Icons.sync, size: 18),
                label: Text(
                  locationState.pendingSyncCount > 0
                      ? l10n.syncNowPending(
                          locationState.pendingSyncCount.toString(),
                        )
                      : l10n.noPendingDataToSync,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (locationState.error != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.red.shade900.withValues(alpha: 0.3) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? Colors.red.shade700 : Colors.red.shade200),
                ),
                child: Text(
                  locationState.error!,
                  style: TextStyle(
                    color: isDark ? Colors.red.shade200 : Colors.red.shade800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    DashboardState state,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.todaysDeliveries,
                value: state.todaysDeliveries.toString(),
                icon: Icons.local_shipping,
                onTap: () => context.push('/delivery-history'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.salesReturns,
                value: state.todaysSalesReturns.toString(),
                icon: Icons.assignment_return,
                onTap: () => context.push('/sales-return-history'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: l10n.categories,
                value: state.categories.length.toString(),
                icon: Icons.category,
                onTap: () => context.push('/categories'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                title: l10n.products,
                value: state.assignedProductsCount.toString(),
                icon: Icons.inventory_2,
                onTap: () => context.push('/products'),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: double.infinity,
          child: StatCard(
            title: l10n.customers,
            value: state.assignedCustomersCount.toString(),
            icon: Icons.people,
            badgeCount: state.rejectedCustomers.length,
            onTap: () => context.push('/customer-sync-status'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        QuickActionCard(
          title: l10n.customers,
          subtitle: l10n.manageCustomers,
          icon: Icons.people_outline,
          color: Theme.of(context).colorScheme.primaryContainer,
          onTap: () => context.push('/customers'),
        ),
        const SizedBox(height: 8),
        QuickActionCard(
          title: l10n.newDelivery,
          subtitle: l10n.createNewDelivery,
          icon: Icons.add_circle_outline,
          color: Theme.of(context).colorScheme.tertiaryContainer,
          onTap: () => context.go('/delivery'),
        ),
        const SizedBox(height: 8),
        QuickActionCard(
          title: l10n.salesReturn,
          subtitle: l10n.recordSalesReturn,
          icon: Icons.assignment_return,
          color: Theme.of(context).colorScheme.secondaryContainer,
          onTap: () => context.go('/sales-return'),
        ),
        const SizedBox(height: 8),
        QuickActionCard(
          title: l10n.sync,
          subtitle: l10n.syncPendingData,
          icon: Icons.sync,
          color: Theme.of(context).colorScheme.tertiaryContainer,
          onTap: () => context.go('/sync'),
        ),
      ],
    );
  }
}
