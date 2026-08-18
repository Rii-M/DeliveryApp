import '../../dto/sales_invoice_request.dart';
import '../../dto/sales_invoice_response.dart';
import '../../dto/sales_return_request.dart';
import '../../dto/customer_operation_result.dart';

abstract class ApiService {
  void updateConfig({String? baseUrl, String? token});
  Future<List<Map<String, dynamic>>> fetchAllProducts();
  Future<List<Map<String, dynamic>>> fetchCustomers();
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String customerId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String customerId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchPaymentModes();
  Future<List<Map<String, dynamic>>> fetchAssignedCategories();
  Future<List<Map<String, dynamic>>> fetchCustomerDiscountGroups();
  Future<List<Map<String, dynamic>>> fetchCategoryWiseDiscounts();
  Future<CustomerOperationResult> addCustomer(Map<String, dynamic> data);
  Future<CustomerOperationResult> updateCustomer(
      Map<String, dynamic> data, String recordId);
  
  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request);
  Future<bool> createSalesReturn(Map<String, dynamic> data);
  Future<bool> createSalesReturnV2(SalesReturnRequest request);
}
