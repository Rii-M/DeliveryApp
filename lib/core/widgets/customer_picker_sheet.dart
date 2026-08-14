import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/customer.dart';

/// Bottom sheet that lets the driver pick a customer from a searchable list.
///
/// Used at the very start of the Sales / Sales Return flows, and again later
/// to change the selected customer. Rendered as an in-page overlay (not a
/// separate route) so it never lingers on other pages after navigating away.
class CustomerPickerSheet extends StatefulWidget {
  final List<Customer> customers;
  final Customer? selectedCustomer;
  final ValueChanged<Customer> onCustomerSelected;

  const CustomerPickerSheet({
    super.key,
    required this.customers,
    this.selectedCustomer,
    required this.onCustomerSelected,
  });

  @override
  State<CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<CustomerPickerSheet> {
  static const int _initialVisibleCount = 5;

  final _searchController = TextEditingController();
  late List<Customer> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.customers.take(_initialVisibleCount).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CustomerPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.customers, widget.customers)) {
      _onSearchChanged(_searchController.text);
    }
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.customers.take(_initialVisibleCount).toList();
      } else {
        _filtered = widget.customers
            .where(
              (c) =>
                  c.name.toLowerCase().contains(query) ||
                  (c.phone?.toLowerCase().contains(query) ?? false) ||
                  (c.address?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.selectCustomer,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(height: 8),
                  Flexible(
                    child: _filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Text(
                                l10n.noCustomersFound,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final customer = _filtered[index];
                              final isSelected =
                                  customer.serverId ==
                                  widget.selectedCustomer?.serverId;
                              return ListTile(
                                selected: isSelected,
                                selectedTileColor: theme
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.4),
                                leading: CircleAvatar(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Text(
                                    customer.name.isNotEmpty
                                        ? customer.name[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  customer.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle:
                                    customer.address != null &&
                                        customer.address!.isNotEmpty
                                    ? Text(
                                        customer.address!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: isSelected
                                    ? Icon(
                                        Icons.check_circle,
                                        color: theme.colorScheme.primary,
                                      )
                                    : null,
                                onTap: () =>
                                    widget.onCustomerSelected(customer),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
