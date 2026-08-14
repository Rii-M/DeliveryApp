import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer_area.dart';
import '../../../models/customer_discount_group.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  List<CustomerDiscountGroup> _discountGroups = [];
  List<CustomerArea> _areas = [];
  CustomerDiscountGroup? _selectedDiscountGroup;
  CustomerArea? _selectedArea;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = ref.read(apiServiceProvider);
      final discountGroupData = await apiService.fetchCustomerDiscountGroups();
      final areaData = await apiService.fetchAreas();
      if (!mounted) return;
      setState(() {
        _discountGroups = discountGroupData
            .map(CustomerDiscountGroup.fromJson)
            .where((g) => g.isActive)
            .toList();
        _areas = areaData
            .map(CustomerArea.fromJson)
            .where((a) => a.isActive)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSaving = true);

    final payload = <String, dynamic>{
      'Name': _nameController.text.trim(),
      'Mobile': _mobileController.text.trim(),
      'Email': _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      'Address': _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      'CustomerDiscountGroupId': _selectedDiscountGroup!.id,
      'AreaId': _selectedArea!.id,
      'AgentId': null,
      'ClassName': null,
      'Code': null,
      'CreditLimit': 0,
      'DOB': null,
      'IsActive': true,
      'IsAllowCredit': true,
      'MappedBranchId': null,
      'MappedDepartmentId': null,
      'MetaData': '{"ContactPersons":[]}',
      'PAN': null,
      'ReferenceBranchId': null,
      'ReferredBy': null,
      'SetAsSupplier': false,
    };

    try {
      final success =
          await ref.read(apiServiceProvider).addCustomer(payload);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.customerAddedSuccessfully)),
        );
        context.pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToAddCustomer)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Widget _buildErrorView(ThemeData theme, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadOptions,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addCustomer)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView(theme, l10n)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: l10n.customerName,
                            hintText: l10n.customerName,
                            prefixIcon: const Icon(Icons.person_outline),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterCustomerName;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: l10n.customerMobile,
                            hintText: l10n.customerMobile,
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.enterCustomerMobile;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: l10n.email,
                            hintText: l10n.email,
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: l10n.address,
                            hintText: l10n.address,
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CustomerDiscountGroup>(
                          initialValue: _selectedDiscountGroup,
                          decoration: InputDecoration(
                            labelText: l10n.discountGroup,
                            hintText: l10n.selectDiscountGroup,
                            prefixIcon: const Icon(Icons.percent),
                            border: const OutlineInputBorder(),
                          ),
                          items: _discountGroups
                              .map(
                                (g) => DropdownMenuItem(
                                  value: g,
                                  child: Text(g.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDiscountGroup = value),
                          validator: (value) {
                            if (value == null) {
                              return l10n.selectDiscountGroupRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CustomerArea>(
                          initialValue: _selectedArea,
                          decoration: InputDecoration(
                            labelText: l10n.area,
                            hintText: l10n.selectArea,
                            prefixIcon: const Icon(Icons.map_outlined),
                            border: const OutlineInputBorder(),
                          ),
                          items: _areas
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedArea = value),
                          validator: (value) {
                            if (value == null) {
                              return l10n.selectAreaRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.person_add),
                          label: Text(_isSaving ? l10n.saving : l10n.save),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
