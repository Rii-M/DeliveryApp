import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_storage.dart';
import '../../../core/auth/shared_auth_state.dart';
import '../../../core/network/providers.dart';
import '../../../features/sync/provider/sync_provider.dart';
import '../../../repositories/auth_repository.dart';
import '../models/selection_option.dart';
import '../../location/location_provider.dart';
import '../../dashboard/provider/dashboard_provider.dart';
import '../../sales_return/provider/sales_return_provider.dart';
import '../../delivery/provider/delivery_provider.dart';

enum AuthStatus { uninitialized, unauthenticated, authenticated }

class AuthState {
  final AuthStatus status;
  final bool isLoading;
  final String? error;
  final String? baseUrl;
  final String? companyCode;
  final String? tempToken;
  final String? finalToken;
  final String? userId;
  final String? customerId;
  final String? driverId;
    final String? driverName;
  final String? userName;
  final String? email;
  final String? outletId;
  final List<SelectionOption>? companies;
  final List<SelectionOption>? branches;
  final List<SelectionOption>? departments;
  final List<SelectionOption>? fiscalYears;

  const AuthState({
    this.status = AuthStatus.uninitialized,
    this.isLoading = false,
    this.error,
    this.baseUrl,
    this.companyCode,
    this.tempToken,
    this.finalToken,
    this.userId,
    this.customerId,
    this.driverId,
    this.driverName,
    this.userName,
    this.email,
    this.outletId,
    this.companies,
    this.branches,
    this.departments,
    this.fiscalYears,
  });

  AuthState copyWith({
    AuthStatus? status,
    bool? isLoading,
    String? error,
    String? baseUrl,
    String? companyCode,
    String? tempToken,
    String? finalToken,
    String? userId,
    String? customerId,
    String? driverId,
    String? driverName,
    String? userName,
    String? email,
    String? outletId,
    List<SelectionOption>? companies,
    List<SelectionOption>? branches,
    List<SelectionOption>? departments,
    List<SelectionOption>? fiscalYears,
  }) {
    return AuthState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      baseUrl: baseUrl ?? this.baseUrl,
      companyCode: companyCode ?? this.companyCode,
      tempToken: tempToken ?? this.tempToken,
      finalToken: finalToken ?? this.finalToken,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      outletId: outletId ?? this.outletId,
      companies: companies ?? this.companies,
      branches: branches ?? this.branches,
      departments: departments ?? this.departments,
      fiscalYears: fiscalYears ?? this.fiscalYears,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  final AuthRepository _authRepo = AuthRepository();

  AuthNotifier(this._ref) : super(const AuthState()) {
    sharedAuthState.onUnauthorized = () async {
      await clearAuthData();
      state = const AuthState(status: AuthStatus.unauthenticated);
    };
    _init();
  }

  Future<void> _init() async {
    final hasAuth = await hasSavedAuth();
    if (hasAuth) {
      final token = await getSavedToken();
      final baseUrl = await getSavedBaseUrl();
      final userId = await getSavedUserId();
      final customerId = await getSavedCustomerId();
      final driverId = await getSavedDriverId();
      final driverName = await getSavedDriverName();
      final userName = await getSavedUserName();
      final email = await getEmail();
      final outletId = await getSavedOutletId();
      if (token != null && baseUrl != null) {
        _applyAuthConfig(baseUrl, token);
        state = AuthState(
          status: AuthStatus.authenticated,
          finalToken: token,
          baseUrl: baseUrl,
          userId: userId,
          customerId: customerId,
          driverId: driverId,
          driverName: driverName,
          userName: userName,
          email: email,
          outletId: outletId,
        );
        return;
      }
    }
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> login({
    required String companyCode,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      companyCode: companyCode,
    );

    try {
      final companyData = await _authRepo.getCompanyUrl(companyCode);
      final website = companyData['Website'] as String?;
      if (website == null || website.isEmpty) {
        throw Exception('Invalid company URL');
      }
      final baseUrl = website.endsWith('/') ? website.substring(0, website.length - 1) : website;
      state = state.copyWith(baseUrl: baseUrl);

      final step1Data = await _authRepo.step1(
        baseUrl: baseUrl,
        username: username,
        password: password,
      );
      final token1 = step1Data['Token'] as String?;
      if (token1 == null || token1.isEmpty) {
        throw Exception('Invalid token received');
      }

      final companies = AuthRepository.parseOptions(step1Data['Companies'] as List<dynamic>?);

      if (companies.isEmpty) {
        throw Exception('No companies available');
      }

      if (companies.length == 1) {
        await _proceedAfterCompany(
          baseUrl: baseUrl,
          token: token1,
          companyId: companies.first.id,
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.unauthenticated,
        baseUrl: baseUrl,
        tempToken: token1,
        companies: companies,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> selectCompany(String companyId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _proceedAfterCompany(
        baseUrl: state.baseUrl!,
        token: state.tempToken!,
        companyId: companyId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _proceedAfterCompany({
    required String baseUrl,
    required String token,
    required String companyId,
  }) async {
    final step2Data = await _authRepo.step2(
      baseUrl: baseUrl,
      token: token,
      companyId: companyId,
    );
    final token2 = step2Data['Token'] as String?;
    if (token2 == null || token2.isEmpty) {
      throw Exception('Invalid token received');
    }

    final branches = AuthRepository.parseOptions(step2Data['Branches'] as List<dynamic>?);

    if (branches.isEmpty) {
      throw Exception('No branches available');
    }

    if (branches.length == 1) {
      await _proceedAfterBranch(
        baseUrl: baseUrl,
        token: token2,
        branchId: branches.first.id,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      tempToken: token2,
      branches: branches,
      companies: null,
    );
  }

  Future<void> selectBranch(String branchId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _proceedAfterBranch(
        baseUrl: state.baseUrl!,
        token: state.tempToken!,
        branchId: branchId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _proceedAfterBranch({
    required String baseUrl,
    required String token,
    required String branchId,
  }) async {
    state = state.copyWith(outletId: branchId);
    final step3Data = await _authRepo.step3(
      baseUrl: baseUrl,
      token: token,
      branchId: branchId,
    );
    final token3 = step3Data['Token'] as String?;
    if (token3 == null || token3.isEmpty) {
      throw Exception('Invalid token received');
    }

    final departments = AuthRepository.parseOptions(step3Data['Departments'] as List<dynamic>?);

    if (departments.isEmpty) {
      throw Exception('No departments available');
    }

    if (departments.length == 1) {
      await _proceedAfterDepartment(
        baseUrl: baseUrl,
        token: token3,
        departmentId: departments.first.id,
        branchId: branchId,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      tempToken: token3,
      departments: departments,
      branches: null,
    );
  }

  Future<void> selectDepartment(String departmentId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _proceedAfterDepartment(
        baseUrl: state.baseUrl!,
        token: state.tempToken!,
        departmentId: departmentId,
        branchId: state.outletId ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _proceedAfterDepartment({
    required String baseUrl,
    required String token,
    required String departmentId,
    required String branchId,
  }) async {
    final step4Data = await _authRepo.step4(
      baseUrl: baseUrl,
      token: token,
      departmentId: departmentId,
    );
    final token4 = step4Data['Token'] as String?;
    if (token4 == null || token4.isEmpty) {
      throw Exception('Invalid token received');
    }

    final fiscalYears = AuthRepository.parseOptions(step4Data['Departments'] as List<dynamic>?);

    if (fiscalYears.isEmpty) {
      throw Exception('No fiscal years available');
    }

    final activeFiscalYear = fiscalYears.cast<SelectionOption?>().firstWhere(
      (fy) => fy!.isActive,
      orElse: () => null,
    );

     if (activeFiscalYear != null) {
      await _finishLogin(
        baseUrl: baseUrl,
        token: token4,
        fiscalYearId: activeFiscalYear.id,
        outletId: branchId,
      );
      return;
    }

    if (fiscalYears.length == 1) {
      await _finishLogin(
        baseUrl: baseUrl,
        token: token4,
        fiscalYearId: fiscalYears.first.id,
        outletId: branchId,
      );
      return;
    }

    state = state.copyWith(
      isLoading: false,
      tempToken: token4,
      fiscalYears: fiscalYears,
      departments: null,
    );
  }

  Future<void> selectFiscalYear(String fiscalYearId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _finishLogin(
        baseUrl: state.baseUrl!,
        token: state.tempToken!,
        fiscalYearId: fiscalYearId,
        outletId: state.outletId ?? '',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _finishLogin({
    required String baseUrl,
    required String token,
    required String fiscalYearId,
    required String outletId,
  }) async {
    final step5Data = await _authRepo.step5(
      baseUrl: baseUrl,
      token: token,
      fiscalYearId: fiscalYearId,
    );
    final finalToken = step5Data['Token'] as String?;
    if (finalToken == null || finalToken.isEmpty) {
      throw Exception('Invalid token received');
    }

    final userId = step5Data['UserId'] as String?;

    String? userName;
    String? email;
    String? driverName;
    String? resolvedCustomerId;
    String? resolvedDriverId;
    if (userId != null && userId.isNotEmpty) {
      try {
        final profileData = await _authRepo.getProfile(
          baseUrl: baseUrl,
          token: finalToken,
          userId: userId,
        );
        final firstName = profileData['FirstName'] as String? ?? '';
        driverName = firstName;
        final lastName = profileData['LastName'] as String? ?? '';
        userName = '$firstName $lastName'.trim();
        if (userName.isEmpty) userName = null;
        email = profileData['Email'] as String?;
      } catch (e) {
        print('[Auth] getProfile failed: $e');
      }

      try {
        resolvedCustomerId = await _authRepo.getCustomerId(
          baseUrl: baseUrl,
          token: finalToken,
          userId: userId,
        );
      } catch (e) {
        print('[Auth] getCustomerId failed: $e');
      }

      try {
        resolvedDriverId = await _authRepo.getDeliveryBoyId(
          baseUrl: baseUrl,
          token: finalToken,
          userId: userId,
        );
      } catch (e) {
        print('[Auth] getDeliveryBoyId failed: $e');
      }
    }

    final customerId = resolvedCustomerId ?? userId;
    final driverId = resolvedDriverId ?? userId;
    print('[Auth] userId=$userId, customerId=$customerId, driverId=$driverId');

    await saveAuthData(
      token: finalToken,
      baseUrl: baseUrl,
      userId: userId,
      customerId: customerId,
      driverId: driverId,
      driverName: driverName,
      userName: userName,
      email : email,
      outletId: outletId,
    );
    _applyAuthConfig(baseUrl, finalToken);
    sharedAuthState.reset();

    state = AuthState(
      status: AuthStatus.authenticated,
      baseUrl: baseUrl,
      finalToken: finalToken,
      userId: userId,
      customerId: customerId,
      driverId: driverId,
      driverName: driverName,
      userName: userName,
      email:email,
      outletId: outletId,
    );

    // Future.microtask(() => _ref.read(syncProvider.notifier).syncAll());
    Future.microtask(() async {
     await _ref.read(syncProvider.notifier).syncAll();
     await _ref.read(dashboardProvider.notifier).refresh();
    });
  }

  void _applyAuthConfig(String baseUrl, String token) {
    _ref.read(apiServiceProvider).updateConfig(baseUrl: baseUrl, token: token);
    final dio = _ref.read(dioProvider);
    dio.options.baseUrl = baseUrl;
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> logout() async {
    await _ref.read(locationStateProvider.notifier).stopTracking();
    _ref.read(deliveryFormProvider.notifier).resetForm();
    _ref.read(salesReturnProvider.notifier).reset();
    await clearAuthData();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
