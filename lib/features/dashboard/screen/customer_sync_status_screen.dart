import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/rejected_customer.dart';
import '../../../repositories/dashboard_repository.dart';
import '../provider/dashboard_provider.dart';

class CustomerSyncStatusScreen extends ConsumerStatefulWidget {
  const CustomerSyncStatusScreen({super.key});

  @override
  ConsumerState<CustomerSyncStatusScreen> createState() =>
      _CustomerSyncStatusScreenState();
}

class _CustomerSyncStatusScreenState
    extends ConsumerState<CustomerSyncStatusScreen> {
  List<Map<String, dynamic>> _entries = [];
  List<RejectedCustomer> _rejected = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final entries = await repo.getCustomerSyncStatus();
      final rejected = await repo.getRejectedCustomers();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _rejected = rejected;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;
    ref.read(dashboardProvider.notifier).loadDashboard();
  }

  Future<void> _clearRejected(RejectedCustomer customer) async {
    await ref
        .read(dashboardRepositoryProvider)
        .clearRejectedCustomer(customer.id!);
    await _loadData();
    await _refreshDashboard();
  }

  Future<void> _clearAllRejected() async {
    await ref.read(dashboardRepositoryProvider).clearAllRejectedCustomers();
    await _loadData();
    await _refreshDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final pendingEntries = _entries
        .where((e) => (e['status'] as String? ?? '') != 'Synced')
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.customerSyncStatus)),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_rejected.isNotEmpty) ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.rejectedCustomers,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _clearAllRejected,
                            icon: const Icon(Icons.delete_sweep, size: 18),
                            label: Text(l10n.clearAll),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._rejected.map((r) {
                        return _RejectedTile(
                          customer: r,
                          onClear: () => _clearRejected(r),
                          theme: theme,
                          l10n: l10n,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                    children: pendingEntries.map((e) {
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

class _RejectedTile extends StatelessWidget {
  final RejectedCustomer customer;
  final VoidCallback onClear;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _RejectedTile({
    required this.customer,
    required this.onClear,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.person_off,
              size: 18, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  Text(
                    customer.phone!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  customer.reason ?? l10n.notSynced,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close, size: 18),
            color: theme.colorScheme.onErrorContainer,
            tooltip: l10n.clear,
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
