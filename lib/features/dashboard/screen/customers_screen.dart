import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../../../repositories/customer_repository.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  static const int _initialVisibleCount = 8;

  final _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filtered = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customers =
          await ref.read(customerRepositoryProvider).getCachedCustomers();
      if (!mounted) return;
      setState(() {
        _allCustomers = customers;
        _applyFilter();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      _filtered = _allCustomers.take(_initialVisibleCount).toList();
    } else {
      _filtered = _allCustomers
          .where(
            (c) =>
                c.name.toLowerCase().contains(query) ||
                (c.phone?.toLowerCase().contains(query) ?? false) ||
                (c.address?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }
  }

  void _onSearchChanged(String value) {
    setState(_applyFilter);
  }

  Future<void> _openAddCustomer() async {
    final added = await context.push<bool>('/add-customer');
    if (added == true) {
      _loadData();
    }
  }

  Future<void> _openEditCustomer(Customer customer) async {
    final updated = await context.push<bool>('/add-customer', extra: customer);
    if (updated == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customers),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addCustomer,
            onPressed: _openAddCustomer,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: l10n.searchCustomer,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.trim().isEmpty
                                ? l10n.noCustomersAvailable
                                : l10n.noCustomersFound,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final customer = _filtered[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase()
                                        : '?',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: customer.phone != null &&
                                        customer.phone!.isNotEmpty
                                    ? Text(customer.phone!)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: l10n.editCustomer,
                                  onPressed: () =>
                                      _openEditCustomer(customer),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}