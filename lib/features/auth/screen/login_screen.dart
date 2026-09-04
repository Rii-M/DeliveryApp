import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../models/selection_option.dart';
import '../provider/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _companyCodeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _companyCodeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (prev?.error != null && next.error == null) {
        return;
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    if (state.companies != null && state.companies!.length > 1) {
      return _buildSelectionScreen(
        title: AppLocalizations.of(context)!.selectCompany,
        options: state.companies!,
        onSelected: (id) => ref.read(authProvider.notifier).selectCompany(id),
      );
    }

    if (state.branches != null && state.branches!.length > 1) {
      return _buildSelectionScreen(
        title: AppLocalizations.of(context)!.selectBranch,
        options: state.branches!,
        onSelected: (id) => ref.read(authProvider.notifier).selectBranch(id),
      );
    }

    if (state.departments != null && state.departments!.length > 1) {
      return _buildSelectionScreen(
        title: AppLocalizations.of(context)!.selectDepartment,
        options: state.departments!,
        onSelected: (id) => ref.read(authProvider.notifier).selectDepartment(id),
      );
    }

    if (state.fiscalYears != null && state.fiscalYears!.length > 1) {
      return _buildSelectionScreen(
        title: AppLocalizations.of(context)!.selectFiscalYear,
        options: state.fiscalYears!,
        onSelected: (id) => ref.read(authProvider.notifier).selectFiscalYear(id),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/icon/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.posDelivery,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nanglo Bakeries',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _companyCodeController,
                          decoration: InputDecoration(
                            labelText: l10n.companyCode,
                            prefixIcon: const Icon(Icons.business),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty
                                  ? l10n.enterCompanyCode
                                  : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: l10n.username,
                            prefixIcon: const Icon(Icons.person),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.enterUsername : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: l10n.password,
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? l10n.enterPassword : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      ref.read(authProvider.notifier).login(
                                            companyCode: _companyCodeController
                                                .text
                                                .trim(),
                                            username:
                                                _usernameController.text.trim(),
                                            password: _passwordController.text,
                                          );
                                    }
                                  },
                            child: state.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    l10n.login,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildSelectionScreen({
    required String title,
    required List<SelectionOption> options,
    required Function(String) onSelected,
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: options.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final option = options[index];
          return ListTile(
            title: Text(option.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelected(option.id),
          );
        },
      ),
    );
  }
}
