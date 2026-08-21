import 'sales_invoice_request.dart';

class SalesReturnRequest {
  final String transactionDate;
  final String transactionDateBS;
  final String type;
  final bool isReturn;
  final bool isSettled;
  final String? customerId;
  final String? customerName;
  final String? remarks;
  final String? returnReason;
  final double changeAmount;
  final String? deliveryBoyId;
  final String? deliveryBoyName;
  final String? invoiceNumber;
  final String? invoiceRefNumber;
  final String outletId;
  final String chalanId;
  final String chalanNumber;
  final String? payMode;
  final double roundoffAmount;
  final double totalDiscount;
  final double totalDiscountIncludingTax;
  final double totalGrossAmount;
  final double totalGrossAmountIncludingTax;
  final double totalNetAmount;
  final double totalNonTaxableAmount;
  final double totalPayableAmount;
  final double totalQuantity;
  final double totalTax;
  final double totalTaxableAmount;
  final double tenderAmount;
  final List<SalesInvoiceTaxRequest> salesInvoiceTax;
  final List<SalesInvoiceItemRequest> salesInvoiceItem;
  final List<SalesInvoicePaymentRequest> salesInvoicePayment;
  final String refImageDocumentId;
  final List<dynamic> additionalCharges;
  final double volumeDiscount;
  final String currencyId;
  final String currencyName;

  SalesReturnRequest({
    required this.transactionDate,
    this.transactionDateBS = '',
    this.type = 'Return',
    this.isReturn = true,
    this.isSettled = true,
    this.customerId,
    this.customerName,
    this.remarks,
    this.returnReason,
    this.changeAmount = 0,
    this.deliveryBoyId,
    this.deliveryBoyName,
    this.invoiceNumber = '',
    this.invoiceRefNumber = '',
    required this.outletId,
    this.chalanId = '',
    this.chalanNumber = '',
    this.payMode,
    this.roundoffAmount = 0,
    required this.totalDiscount,
    required this.totalDiscountIncludingTax,
    required this.totalGrossAmount,
    required this.totalGrossAmountIncludingTax,
    required this.totalNetAmount,
    required this.totalNonTaxableAmount,
    required this.totalPayableAmount,
    required this.totalQuantity,
    required this.totalTax,
    required this.totalTaxableAmount,
    required this.tenderAmount,
    required this.salesInvoiceTax,
    required this.salesInvoiceItem,
    required this.salesInvoicePayment,
    this.refImageDocumentId = '',
    this.additionalCharges = const [],
    this.volumeDiscount = 0,
    required this.currencyId,
    this.currencyName = 'NRs',
  });

  Map<String, dynamic> toJson() {
    return {
      'TransactionDate': transactionDate,
      'TransactionDateBS': transactionDateBS,
      'Type': type,
      'IsReturn': isReturn,
      'IsSettled': isSettled,
      'CustomerId': customerId ?? '',
      'CustomerName': customerName ?? '',
      'Remarks': remarks ?? '',
      'ReturnReason': returnReason ?? '',
      'ChangeAmount': changeAmount,
      'DeliveryBoyId': deliveryBoyId ?? '',
      'DeliveryBoyName': deliveryBoyName ?? '',
      'InvoiceNumber': invoiceNumber ?? '',
      'InvoiceRefNumber': invoiceRefNumber ?? '',
      'OutletId': outletId,
      'ChalanId': chalanId,
      'ChalanNumber': chalanNumber,
      'PayMode': payMode ?? '',
      'RoundoffAmount': roundoffAmount,
      'TotalDiscount': totalDiscount,
      'TotalDiscountIncludingTax': totalDiscountIncludingTax,
      'TotalGrossAmount': totalGrossAmount,
      'TotalGrossAmountIncludingTax': totalGrossAmountIncludingTax,
      'TotalNetAmount': totalNetAmount,
      'TotalNonTaxableAmount': totalNonTaxableAmount,
      'TotalPayableAmount': totalPayableAmount,
      'TotalQuantity': totalQuantity,
      'TotalTax': totalTax,
      'TotalTaxableAmount': totalTaxableAmount,
      'TenderAmount': tenderAmount,
      'SalesInvoiceTax': salesInvoiceTax.map((e) => e.toJson()).toList(),
      'SalesInvoiceItem': salesInvoiceItem.map((e) => e.toJson()).toList(),
      'SalesInvoicePayment': salesInvoicePayment.map((e) => e.toJson()).toList(),
      'RefImageDocumentId': refImageDocumentId,
      'AdditionalCharges': additionalCharges,
      'VolumeDiscount': volumeDiscount,
      'CurrencyId': currencyId,
      'CurrencyName': currencyName,
    };
  }
}