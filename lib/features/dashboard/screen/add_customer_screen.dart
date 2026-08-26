import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/providers.dart';
import '../../../features/sync/provider/sync_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/customer.dart';
import '../../../models/customer_discount_group.dart';
import '../../../models/area.dart';
import '../../../models/customer_group.dart';
import '../../../repositories/area_repository.dart';
import '../../../repositories/customer_repository.dart';
import '../../../repositories/customer_group_repository.dart';
import '../../../repositories/discount_group_repository.dart';
import '../provider/dashboard_provider.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  final Customer? customer;

  const AddCustomerScreen({super.key, this.customer});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _panController = TextEditingController();

  List<CustomerDiscountGroup> _discountGroups = [];
  CustomerDiscountGroup? _selectedDiscountGroup;
  List<Area> _areas = [];
  Area? _selectedArea;
  List<CustomerGroup> _customerGroups = [];
  CustomerGroup? _selectedCustomerGroup;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final customer = widget.customer;
    if (customer != null) {
      _nameController.text = customer.name;
      _mobileController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _addressController.text = customer.address ?? '';
      _panController.text = customer.pan ?? '';
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final discountGroupRepo = ref.read(discountGroupRepositoryProvider);
      final areaRepo = ref.read(areaRepositoryProvider);
      final customerGroupRepo = ref.read(customerGroupRepositoryProvider);

      // Offline-first: show cached groups immediately (rendered below), and
      // best-effort refresh from the server so new groups appear when online.
      List<CustomerDiscountGroup> groups;
      try {
        groups = await discountGroupRepo.getDiscountGroups();
      } catch (_) {
        groups = await discountGroupRepo.getCachedDiscountGroups();
      }

      // Areas follow the same offline-first pattern: use cached areas when
      // available, otherwise fetch from the server and cache them locally so
      // customer creation keeps working offline.
      List<Area> areas;
      try {
        areas = await areaRepo.getAreas();
      } catch (_) {
        areas = await areaRepo.getCachedAreas();
      }

      // Customer groups follow the same offline-first pattern as areas.
      List<CustomerGroup> customerGroups;
      try {
        customerGroups = await customerGroupRepo.getCustomerGroups();
      } catch (_) {
        customerGroups = await customerGroupRepo.getCachedCustomerGroups();
      }

      if (!mounted) return;
      setState(() {
        _discountGroups = groups;
        if (_isEditing && widget.customer!.discountGroupId != null) {
          _selectedDiscountGroup = _discountGroups
              .cast<CustomerDiscountGroup?>()
              .firstWhere(
                (g) => g?.id == widget.customer!.discountGroupId,
                orElse: () => null,
              );
        }
        _areas = areas;
        if (_isEditing && widget.customer!.areaId != null) {
          _selectedArea = _areas.cast<Area?>().firstWhere(
                (a) => a?.id == widget.customer!.areaId,
                orElse: () => null,
              );
        }
        _customerGroups = customerGroups;
        if (_isEditing && widget.customer!.customerGroupId != null) {
          _selectedCustomerGroup = _customerGroups
              .cast<CustomerGroup?>()
              .firstWhere(
                (g) => g?.id == widget.customer!.customerGroupId,
                orElse: () => null,
              );
        }
        _isLoading = false;
      });
      if (groups.isNotEmpty) {
        try {
          await discountGroupRepo.refetch();
          final fresh = await discountGroupRepo.getCachedDiscountGroups();
          if (!mounted) return;
          setState(() {
            _discountGroups = fresh;
            if (_selectedDiscountGroup != null) {
              _selectedDiscountGroup = fresh
                  .cast<CustomerDiscountGroup?>()
                  .firstWhere(
                    (g) => g?.id == _selectedDiscountGroup!.id,
                    orElse: () => _selectedDiscountGroup,
                  );
            }
          });
        } catch (_) {
          // offline - keep using cached groups
        }
      }
      if (areas.isNotEmpty) {
        try {
          await areaRepo.refetch();
          final fresh = await areaRepo.getCachedAreas();
          if (!mounted) return;
          setState(() {
            _areas = fresh;
            if (_selectedArea != null) {
              _selectedArea = fresh.cast<Area?>().firstWhere(
                    (a) => a?.id == _selectedArea!.id,
                    orElse: () => _selectedArea,
                  );
            }
          });
        } catch (_) {
          // offline - keep using cached areas
        }
      }
      if (customerGroups.isNotEmpty) {
        try {
          await customerGroupRepo.refetch();
          final fresh = await customerGroupRepo.getCachedCustomerGroups();
          if (!mounted) return;
          setState(() {
            _customerGroups = fresh;
            if (_selectedCustomerGroup != null) {
              _selectedCustomerGroup = fresh
                  .cast<CustomerGroup?>()
                  .firstWhere(
                    (g) => g?.id == _selectedCustomerGroup!.id,
                    orElse: () => _selectedCustomerGroup,
                  );
            }
          });
        } catch (_) {
          // offline - keep using cached customer groups
        }
      }
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

    final customerRepo = ref.read(customerRepositoryProvider);
    final isOnline = await ref.read(networkCheckerProvider).isConnected;

    // When online, check the mobile number against the server BEFORE saving
    // locally so a duplicate is caught immediately and the customer isn't
    // saved. When offline we save locally (offline-first) and queue for sync.
    try {
      if (isOnline) {
        final mobileTaken = await customerRepo.isMobileTakenOnServer(
          _mobileController.text,
          excludeCustomerId: _isEditing ? widget.customer!.serverId : null,
        );
        if (mobileTaken) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.customerMobileAlreadyExists)),
          );
          return;
        }
      }

      final Customer? saved;
      if (_isEditing) {
        saved = await customerRepo.updateCustomerOffline(
          serverId: widget.customer!.serverId,
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          pan: _panController.text.trim().isEmpty
              ? null
              : _panController.text.trim(),
          discountGroupId: _selectedDiscountGroup!.id,
          areaId: _selectedArea!.id,
          customerGroupId: _selectedCustomerGroup!.id,
        );
      } else {
        saved = await customerRepo.saveNewCustomerOffline(
          name: _nameController.text.trim(),
          mobile: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          pan: _panController.text.trim().isEmpty
              ? null
              : _panController.text.trim(),
          discountGroupId: _selectedDiscountGroup!.id,
          areaId: _selectedArea!.id,
          customerGroupId: _selectedCustomerGroup!.id,
        );
      }

      // If online, push to server immediately (no "Sync All" needed). If
      // offline, the customer stays queued for a later sync.
      if (saved.id != null) {
        var synced = !isOnline;
        if (isOnline) {
          try {
            synced = await ref
                .read(syncProvider.notifier)
                .syncCustomerNow(saved.id!);
          } catch (_) {
            synced = false;
            // leftovers stay queued for the next sync run
          }
        }
        if (!mounted) return;
        setState(() => _isSaving = false);
        ref.read(dashboardProvider.notifier).loadDashboard();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              synced
                  ? (_isEditing
                      ? l10n.customerUpdatedSuccessfully
                      : l10n.customerAddedSuccessfully)
                  : l10n.customerNotSaved,
            ),
          ),
        );
        context.pop(true);
        return;
      }

      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? l10n.customerUpdatedSuccessfully
                : l10n.customerAddedSuccessfully,
          ),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
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
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCustomer : l10n.addCustomer),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView(theme, l10n)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            readOnly: _isEditing,
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
                            controller: _panController,
                            textCapitalization: TextCapitalization.characters,
                            readOnly: _isEditing,
                            decoration: InputDecoration(
                              labelText: l10n.pan,
                              hintText: l10n.pan,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.enterPan;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              labelText: l10n.address,
                              hintText: l10n.address,
                              prefixIcon: const Icon(
                                Icons.location_on_outlined,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<Area>(
                            initialValue: _selectedArea,
                            decoration: InputDecoration(
                              labelText: l10n.area,
                              hintText: l10n.selectArea,
                              prefixIcon: const Icon(
                                Icons.place_outlined,
                              ),
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
                          DropdownButtonFormField<CustomerGroup>(
                            initialValue: _selectedCustomerGroup,
                            decoration: InputDecoration(
                              labelText: l10n.customerGroup,
                              hintText: l10n.selectCustomerGroup,
                              prefixIcon: const Icon(Icons.group_outlined),
                              border: const OutlineInputBorder(),
                            ),
                            items: _customerGroups
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                                () => _selectedCustomerGroup = value),
                            validator: (value) {
                              if (value == null) {
                                return l10n.selectCustomerGroupRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:SizedBox( 
                      width: double.infinity,
                      child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.person_add),
                      label: Text(_isSaving ? l10n.saving : l10n.save),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
