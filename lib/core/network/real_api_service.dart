import 'package:dio/dio.dart';

import '../../dto/sales_invoice_request.dart';
import '../../dto/sales_invoice_response.dart';
import '../../dto/sales_return_request.dart';
import 'api_config.dart';
import 'api_service.dart';

class RealApiService implements ApiService {
  late final Dio _dio;

  RealApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Authorization': 'Bearer ${ApiConfig.staticBearerToken}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  @override
  void updateConfig({String? baseUrl, String? token}) {
    if (baseUrl != null) {
      _dio.options.baseUrl = baseUrl;
    }
    if (token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<List<Map<String, dynamic>>> _fetchList(String endpoint) async {
    final response = await _dio.get(endpoint);
    final body = response.data as Map<String, dynamic>;
    if (body['Status'] != true) {
      throw Exception(body['Message'] ?? 'API returned status false');
    }
    final data = body['Data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    return _fetchList(
      '${ApiConfig.categoryEndpoint}?customerId=$customerId&transactionDate=$transactionDate',
    );
  }

  @override
Future<List<Map<String, dynamic>>> fetchAssignedCategories() async {
  final response = await _dio.get(ApiConfig.allCategoryEndpoint);
  final body = response.data as Map<String, dynamic>;
  final success = body['success'] ?? body['Status'] ?? false;
  if (success != true) {
    throw Exception(body['message'] ?? body['Message'] ?? 'API returned status false');
  }
  final data = body['data'] ?? body['Data'] ?? [];
  if (data is List) {
    return data.cast<Map<String, dynamic>>();
  }
  return [];
}

  @override
  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final response = await _dio.get(
      ApiConfig.customerEndpoint,
      queryParameters: {'customernamesearch': ''},
    );
    final body = response.data as Map<String, dynamic>;
    final status = body['Status'] ?? body['status'] ?? false;
    if (status != true) {
      throw Exception(body['Message'] ?? body['message'] ?? 'API returned status false');
    }
    final data = body['Data'] ?? body['data'] ?? [];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String customerId,
    required String transactionDate,
  }) async {
    return _fetchList(
      '${ApiConfig.productEndpoint}?customerId=$customerId&transactionDate=$transactionDate',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPaymentModes() async {
    return _fetchList(ApiConfig.paymodeEndpoint);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCustomerDiscountGroups() async {
    return _fetchList(ApiConfig.customerDiscountGroupEndpoint);
  }

  @override
  Future<bool> addCustomer(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConfig.customerAddEndpoint, data: data);
    final body = response.data as Map<String, dynamic>;
    final status = body['Status'] == true || body['status'] == true;
    if (!status) {
      print('[API] addCustomer FAILED. Response: ${response.data}');
    }
    return status;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllProducts() async {
    final url = '${_dio.options.baseUrl}${ApiConfig.allProductsEndpoint}';
    print('[API] Calling AllProducts: $url');
    try {
      final response = await _dio.get(ApiConfig.allProductsEndpoint);
      print('[API] AllProducts response status: ${response.statusCode}');
      final body = response.data as Map<String, dynamic>;
      print('[API] AllProducts response body: ${body.toString().substring(0, body.toString().length.clamp(0, 500))}');
      if (body['Status'] != true) {
        throw Exception(body['Message'] ?? 'API returned status false');
      }
      final data = body['Data'];
      if (data is List) {
        print('[API] AllProducts got ${data} products');
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('[API] AllProducts ERROR: $e');
      rethrow;
    }
  }
  @override
  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request) async {
    final response = await _dio.post(
      ApiConfig.salesInvoiceAddEndpoint,
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    final result = SalesInvoiceResponse.fromJson(body);
    if (!result.success) {
      print('[API] createSalesInvoice FAILED. Response: ${response.data}');
    }
    return result;
  }

  @override
  Future<bool> createSalesReturn(Map<String, dynamic> data) async {
    final response = await _dio.post(
      ApiConfig.salesInvoiceAddEndpoint,
      data: data,
    );
    final body = response.data as Map<String, dynamic>;
    final status = body['Status'] == true || body['status'] == true;
    if (!status) {
      print('[API] createSalesReturn FAILED. Response: ${response.data}');
    }
    return status;
  }

  @override
  Future<bool> createSalesReturnV2(SalesReturnRequest request) async {
    final response = await _dio.post(
      ApiConfig.salesInvoiceAddEndpoint,
      data: request.toJson(),
    );
    final body = response.data as Map<String, dynamic>;
    final status = body['Status'] == true || body['status'] == true;
    if (!status) {
      print('[API] SalesReturnV2 FAILED. Response: ${response.data}');
    }
    return status;
  }
}
