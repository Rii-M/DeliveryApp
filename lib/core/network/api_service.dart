import '../../dto/sales_invoice_request.dart';
import '../../dto/sales_invoice_response.dart';
import '../../dto/sales_return_request.dart';
import '../../dto/customer_operation_result.dart';
import '../../dto/transaction_status_response.dart';

abstract class ApiService {
  void updateConfig({String? baseUrl, String? token});
  Future<List<Map<String, dynamic>>> fetchAllProducts();
  Future<List<Map<String, dynamic>>> fetchCustomers(String deliveryBoyId);
  Future<List<Map<String, dynamic>>> fetchCategories({
    required String deliveryBoyId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchProducts({
    required String deliveryBoyId,
    required String transactionDate,
  });
  Future<List<Map<String, dynamic>>> fetchPaymentModes();
  Future<List<Map<String, dynamic>>> fetchAssignedCategories();
  Future<List<Map<String, dynamic>>> fetchCustomerDiscountGroups();
  Future<List<Map<String, dynamic>>> fetchAreas();
  Future<List<Map<String, dynamic>>> fetchCustomerGroups();
  Future<List<Map<String, dynamic>>> fetchCategoryWiseDiscounts();
  Future<CustomerOperationResult> addCustomer(Map<String, dynamic> data);
  Future<CustomerOperationResult> updateCustomer(
      Map<String, dynamic> data, String recordId);
  
  Future<SalesInvoiceResponse> createSalesInvoice(SalesInvoiceRequest request);
  Future<SalesInvoiceResponse> createSalesReturnV2(SalesReturnRequest request);
  Future<TransactionStatusResponse> getTransactionStatus(int transactionId);
}
