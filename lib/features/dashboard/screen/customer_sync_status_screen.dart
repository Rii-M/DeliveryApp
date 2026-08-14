import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../repositories/dashboard_repository.dart';

class CustomerSyncStatusScreen extends ConsumerStatefulWidget {
  const CustomerSyncStatusScreen({super.key});

  @override
  ConsumerState<CustomerSyncStatusScreen> createState() =>
      _CustomerSyncStatusScreenState();
}

class _CustomerSyncStatusScreenState
    extends ConsumerState<CustomerSyncStatusScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final entries = await ref
          .read(dashboardRepositoryProvider)
          .getCustomerSyncStatus();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    var syncedCount = 0;
    var notSyncedCount = 0;
    for (final e in _entries) {
      final status = (e['status'] as String? ?? '');
      if (status == 'Synced') {
        syncedCount++;
      } else {
        notSyncedCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerSyncStatus)),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _SyncCountChip(
                    label: l10n.synced,
                    count: syncedCount,
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SyncCountChip(
                    label: l10n.notSynced,
                    count: notSyncedCount,
                    icon: Icons.error_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Center(
                  child: Text(
                    l10n.noCustomerSyncEntries,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _entries.map((e) {
                      return _CustomerSyncTile(
                        name: (e['customer_name'] as String? ?? ''),
                        phone: (e['customer_phone'] as String? ?? ''),
                        status: (e['status'] as String? ?? 'Pending'),
                        errorMessage: e['error_message'] as String?,
                        theme: theme,
                        l10n: l10n,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncCountChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _SyncCountChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerSyncTile extends StatelessWidget {
  final String name;
  final String phone;
  final String status;
  final String? errorMessage;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _CustomerSyncTile({
    required this.name,
    required this.phone,
    required this.status,
    required this.errorMessage,
    required this.theme,
    required this.l10n,
  });

  bool get _synced => status == 'Synced';
  bool get _failed => status == 'Failed';

  @override
  Widget build(BuildContext context) {
    final color = _synced
        ? Colors.green
        : _failed
            ? theme.colorScheme.error
            : Colors.orange;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _synced ? Icons.check_circle : Icons.error,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (phone.isNotEmpty)
                  Text(
                    phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (!_synced) ...[
                  const SizedBox(height: 2),
                  Text(
                    errorMessage ?? l10n.notSynced,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _failed
                          ? theme.colorScheme.error
                          : Colors.orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}