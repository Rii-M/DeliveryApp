import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/sync_provider.dart';
import '../widgets/sync_status_tile.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});

  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(syncProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.all(8),
          child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset('assets/icon/logo.png', fit: BoxFit.contain),
              ),
        ),
        title: Text(l10n.sync),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.pendingQueue.isNotEmpty && !state.isSyncing) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.billsPendingSync(state.pendingQueue.length.toString()),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.offlineInvoicesWaiting,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.syncStatus,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SyncStatusTile(
            label: l10n.pending,
            value: state.pendingCount.toString(),
            icon: Icons.hourglass_empty,
            color: theme.colorScheme.tertiaryContainer,
          ),
          SyncStatusTile(
            label: l10n.failed,
            value: state.failedCount.toString(),
            icon: Icons.error_outline,
            color: theme.colorScheme.errorContainer,
          ),
          SyncStatusTile(
            label: l10n.synced,
            value: state.syncedCount.toString(),
            icon: Icons.check_circle_outline,
            color: theme.colorScheme.primaryContainer,
          ),
          // const SizedBox(height: 16),
          // Card(
          //   child: ListTile(
          //     leading: const Icon(Icons.schedule),
          //     title: Text(l10n.lastSync),
          //     subtitle: Text(
          //       state.lastSyncTime?.formattedDateTime ?? l10n.never,
          //     ),
          //   ),
          // ),
          if (state.isSyncing) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.syncing,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (state.incomingStatus.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...state.incomingStatus.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              _incomingIcon(e.value.success),
                              const SizedBox(width: 8),
                              Text(
                                e.value.label,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (state.incomingStatus.isNotEmpty && !state.isSyncing) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.serverData,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...state.incomingStatus.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _incomingIcon(e.value.success),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.value.label,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            if (e.value.error != null && e.value.success == false)
                              Padding(
                                padding: const EdgeInsets.only(left: 22, top: 2),
                                child: Text(
                                  e.value.error!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!state.isSyncing) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(syncProvider.notifier).syncAll(),
              icon: const Icon(Icons.sync),
              label: Text(l10n.syncAll),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            if (state.syncResult) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  l10n.syncCompletedSuccessfully,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
            if (state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  state.errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            if (state.pendingQueue.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                l10n.pendingItems,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...state.pendingQueue.map((entry) {
                return Card(
                  child: ListTile(
                    leading: Icon(
                      entry.entityType == 'Delivery'
                          ? Icons.local_shipping
                          : Icons.receipt_long,
                    ),
                    title: Text('${entry.entityType == 'Delivery' ? 'Sale' : entry.entityType} #${entry.entityId}'),
                    subtitle: Text(
                      l10n.statusLabel(entry.status),
                      style: TextStyle(
                        color: entry.status == 'Failed'
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: _statusIcon(entry.status),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  Widget _incomingIcon(bool? success) {
    if (success == null) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      success ? Icons.check_circle : Icons.error,
      size: 16,
      color: success ? AppColors.success : AppColors.error,
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case 'Synced':
        return const Icon(Icons.check_circle, color: AppColors.success);
      case 'Failed':
        return const Icon(Icons.error, color: AppColors.error);
      case 'Syncing':
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      default:
        return const Icon(Icons.hourglass_empty, color: AppColors.primary);
    }
  }
}
