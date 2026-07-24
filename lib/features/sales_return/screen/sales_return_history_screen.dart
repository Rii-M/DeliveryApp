import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/extensions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../../../models/sales_return.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/sales_return_repository.dart';

class SalesReturnHistoryScreen extends ConsumerStatefulWidget {
  const SalesReturnHistoryScreen({super.key});

  @override
  ConsumerState<SalesReturnHistoryScreen> createState() =>
      _SalesReturnHistoryScreenState();
}

class _SalesReturnHistoryScreenState
    extends ConsumerState<SalesReturnHistoryScreen> {
  List<SalesReturn> _salesReturns = [];
  List<Customer> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final salesReturns =
          await ref.read(salesReturnRepositoryProvider).getSalesReturnsByDate(
                DateTime.now(),
              );
      final customers =
          await ref.read(customerRepositoryProvider).getCachedCustomers();
      setState(() {
        _salesReturns = salesReturns;
        _customers = customers;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _customerName(String customerId) {
    final l10n = AppLocalizations.of(context)!;
    return _customers
            .cast<Customer?>()
            .firstWhere((c) => c?.serverId == customerId, orElse: () => null)
            ?.name ??
        l10n.customerId(customerId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.todaysSalesReturns)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salesReturns.isEmpty
              ? Center(
                  child: Text(
                    l10n.noSalesReturnsForToday,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _salesReturns.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final sr = _salesReturns[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: sr.isSynced
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            child: sr.isSynced
                                ? Icon(Icons.check_circle,
                                    color: Colors.green.shade700)
                                : Icon(Icons.cancel,
                                    color: Colors.red.shade700),
                          ),
                          title: Text(l10n.salesReturnNumber(sr.id.toString())),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_customerName(sr.customerId)}  \u2022   ${l10n.itemCount(sr.items.length.toString())}',
                              ),
                              Text(sr.createdDate.formattedDateTime),
                            ],
                          ),
                          onTap: () {
                            context.push('/sales-return-detail/${sr.id}');
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}