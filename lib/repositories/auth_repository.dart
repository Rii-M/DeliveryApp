import 'package:dio/dio.dart';

import '../features/auth/models/selection_option.dart';

class AuthRepository {
  static const _licenseUrl = 'https://lic.crossoverpms.com';

  Future<Map<String, dynamic>> getCompanyUrl(String companyCode) async {
    final dio = Dio();
    final response = await dio.get(
      '$_licenseUrl/api/company/GetCompanyURL/$companyCode',
    );
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Company not found');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step1({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    final response = await dio.post('/ap1/token/step1', data: {
      'Username': username,
      'Password': password,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Login failed');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step2({
    required String baseUrl,
    required String token,
    required String companyId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.post('/ap1/token/step2', data: {
      'CompanyId': companyId,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Company selection failed');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step3({
    required String baseUrl,
    required String token,
    required String branchId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.post('/ap1/token/step3', data: {
      'BranchId': branchId,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Branch selection failed');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step4({
    required String baseUrl,
    required String token,
    required String departmentId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.post('/ap1/token/step4', data: {
      'DepartmentId': departmentId,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Department selection failed');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> step5({
    required String baseUrl,
    required String token,
    required String fiscalYearId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.post('/ap1/token/step5', data: {
      'FiscalYearId': fiscalYearId,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Fiscal year selection failed');
    }
    return body['Data'] as Map<String, dynamic>;
  }

  Future<String?> getCustomerId({
    required String baseUrl,
    required String token,
    required String userId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    print('[Auth] getCustomerId calling: $baseUrl/ap1/pos/posMobile/getCustomerId?userId=$userId');
    final response = await dio.get(
      '/ap1/pos/posMobile/getCustomerId',
      queryParameters: {'userId': userId},
    );
    print('[Auth] getCustomerId response: ${response.data}');
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Failed to fetch customer ID');
    }
    final data = body['Data'];
    if (data is List && data.isNotEmpty) {
      return data.first['Id'] as String?;
    }
    if (data is Map<String, dynamic>) {
      return data['Id'] as String?;
    }
    return null;
  }

  Future<String?> getDeliveryBoyId({
    required String baseUrl,
    required String token,
    required String userId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    print('[Auth] getDeliveryBoyId calling: $baseUrl/ap1/pos/posMobile/getDeliveryBoyId?userId=$userId');
    final response = await dio.get(
      '/ap1/pos/posMobile/getDeliveryBoyId',
      queryParameters: {'userId': userId},
    );
    print('[Auth] getDeliveryBoyId response: ${response.data}');
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Failed to fetch sales boy ID');
    }
    final data = body['Data'];
    if (data is List && data.isNotEmpty) {
      return data.first['Id'] as String?;
    }
    if (data is Map<String, dynamic>) {
      return data['Id'] as String?;
    }
    return null;
  }

  static List<SelectionOption> parseOptions(List<dynamic>? list) {
    if (list == null || list.isEmpty) return [];
    return list
        .map((e) => SelectionOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getProfile({
    required String baseUrl,
    required String token,
    required String userId,
  }) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));
    final response = await dio.post('/ap1/token/getProfile', data: {
      'Id': userId,
    });
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'Failed to fetch profile');
    }
    return body['Data'] as Map<String, dynamic>;
  }
}
