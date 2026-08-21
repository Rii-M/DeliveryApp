class SalesInvoiceRequest {
  final String transactionDate;
  final String transactionDateBS;
  final String type;
  final bool useImage;
  final String? customerId;
  final String? customerName;
  final dynamic className;
  final dynamic customerMobile;
  final dynamic customerAddress;
  final dynamic customerPan;

  final String chalanId;
  final String chalanNumber;
  final String outletId;
  final double totalQuantity;
  final double totalGrossAmount;
  final double totalGrossAmountIncludingTax;
  final double totalDiscount;
  final double totalDiscountIncludingTax;
  final double totalTaxableAmount;
  final double totalNonTaxableAmount;
  final double totalTax;
  final double totalNetAmount;
  final double roundoffAmount;
  final double totalPayableAmount;
  final String currencyName;
  final String payMode;
  final double tenderAmount;
  final double changeAmount;
  final bool isSettled;
  final List<SalesInvoiceTaxRequest> salesInvoiceTax;
  final List<SalesInvoiceItemRequest> salesInvoiceItem;
  final List<SalesInvoicePaymentRequest> salesInvoicePayment;
  final String refImageDocumentId;
  final List<dynamic> additionalCharges;
  final double volumeDiscount;
  final dynamic orderDate;
  final String currencyId;
  final String remarks;
  final String deliveryBoyId;
  final String deliveryBoyName;

  SalesInvoiceRequest({
    required this.transactionDate,
    this.transactionDateBS = '',
    this.type = 'Tax',
    this.useImage = false,
    this.customerId,
    this.customerName,
    this.className,
    this.customerMobile,
    this.customerAddress,
    this.customerPan,
    this.chalanId = '',
    this.chalanNumber = '',
    required this.outletId,
    required this.totalQuantity,
    required this.totalGrossAmount,
    required this.totalGrossAmountIncludingTax,
    required this.totalDiscount,
    required this.totalDiscountIncludingTax,
    required this.totalTaxableAmount,
    required this.totalNonTaxableAmount,
    required this.totalTax,
    required this.totalNetAmount,
    this.roundoffAmount = 0,
    required this.totalPayableAmount,
    this.currencyName = 'NRs',
    required this.payMode,
    required this.tenderAmount,
    this.changeAmount = 0,
    this.isSettled = true,
    required this.salesInvoiceTax,
    required this.salesInvoiceItem,
    required this.salesInvoicePayment,
    this.refImageDocumentId = '',
    this.additionalCharges = const [],
    this.volumeDiscount = 0,
    this.orderDate,
    required this.currencyId,
    this.remarks='',
    this.deliveryBoyId = '',
    this.deliveryBoyName = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'TransactionDate': transactionDate,
      'TransactionDateBS': transactionDateBS,
      'Type': type,
      'UseImage': useImage,
      'CustomerId': customerId,
      'CustomerName': customerName,
      'ClassName': className,
      'CustomerMobile': customerMobile,
      'CustomerAddress': customerAddress,
      'CustomerPAN': customerPan,
      'ChalanId': chalanId,
      'ChalanNumber': chalanNumber,
      'OutletId': outletId,
      'TotalQuantity': totalQuantity,
      'TotalGrossAmount': totalGrossAmount,
      'TotalGrossAmountIncludingTax': totalGrossAmountIncludingTax,
      'TotalDiscount': totalDiscount,
      'TotalDiscountIncludingTax': totalDiscountIncludingTax,
      'TotalTaxableAmount': totalTaxableAmount,
      'TotalNonTaxableAmount': totalNonTaxableAmount,
      'TotalTax': totalTax,
      'TotalNetAmount': totalNetAmount,
      'RoundoffAmount': roundoffAmount,
      'TotalPayableAmount': totalPayableAmount,
      'CurrencyName': currencyName,
      'PayMode': payMode,
      'TenderAmount': tenderAmount,
      'ChangeAmount': changeAmount,
      'IsSettled': isSettled,
      'SalesInvoiceTax': salesInvoiceTax.map((e) => e.toJson()).toList(),
      'SalesInvoiceItem': salesInvoiceItem.map((e) => e.toJson()).toList(),
      'SalesInvoicePayment': salesInvoicePayment
          .map((e) => e.toJson())
          .toList(),
      'RefImageDocumentId': refImageDocumentId,
      'AdditionalCharges': additionalCharges,
      'VolumeDiscount': volumeDiscount,
      'OrderDate': orderDate,
      'CurrencyId': currencyId,
      'Remarks':remarks,
      'DeliveryBoyId': deliveryBoyId,
      'DeliveryBoyName': deliveryBoyName,
    };
  }
}

class SalesInvoiceTaxRequest {
  final int taxOrder;
  final String name;
  final double taxAmount;

  SalesInvoiceTaxRequest({
    this.taxOrder = 1,
    this.name = 'VAT SALES',
    this.taxAmount = 0,
  });

  Map<String, dynamic> toJson() {
    return {'TaxOrder': taxOrder, 'Name': name, 'TaxAmount': taxAmount};
  }
}

class SalesInvoiceItemRequest {
  final dynamic sku;
  final bool hasSerialNumber;
  final String serialNumber;
  final String refNo;
  final String chalanId;
  final String chalanNumber;
  final String lotNo;
  final String productId;
  final String name;
  final double quantity;
  final String unitId;
  final String unitName;
  final String categoryId;
  final String groupId;
  final double rate;
  final double rateIncludingTax;
  final double grossAmount;
  final double grossAmountIncludingTax;
  final double discountPercent;
  final double discount;
  final double discountIncludingTax;
  final String discountType;
  final String offerId;
  final bool isCombo;
  final bool isMaintainBatchLotNo;
  final bool isNonConversableUnit;
  final double taxable;
  final double nonTaxable;
  final double taxPercent;
  final double taxAmount;
  final double netAmount;
  final List<SalesInvoiceItemTaxRequest> salesInvoiceItemTax;
  final String barcode;
  final String hsCode;
  final String attribute1;
  final String attribute2;

  SalesInvoiceItemRequest({
    this.sku,
    this.hasSerialNumber = false,
    this.serialNumber = '',
    required this.refNo,
    this.chalanId = '',
    this.chalanNumber = '',
    this.lotNo = '',
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    required this.categoryId,
    this.groupId = '00000000-0000-0000-0000-000000000000',
    required this.rate,
    required this.rateIncludingTax,
    required this.grossAmount,
    required this.grossAmountIncludingTax,
    this.discountPercent = 0,
    this.discount = 0,
    this.discountIncludingTax = 0,
    this.discountType = 'Product',
    this.offerId = '',
    this.isCombo = false,
    this.isMaintainBatchLotNo = false,
    this.isNonConversableUnit = false,
    this.taxable = 0,
    required this.nonTaxable,
    this.taxPercent = 0,
    this.taxAmount = 0,
    required this.netAmount,
    required this.salesInvoiceItemTax,
    this.barcode = '',
    this.hsCode = '',
    this.attribute1 = '',
    this.attribute2 = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'SKU': sku,
      'HasSerialNumber': hasSerialNumber,
      'SerialNumber': serialNumber,
      'RefNo': refNo,
      'ChalanId': chalanId,
      'ChalanNumber': chalanNumber,
      'LotNo': lotNo,
      'ProductId': productId,
      'Name': name,
      'Quantity': quantity,
      'UnitId': unitId,
      'UnitName': unitName,
      'CategoryId': categoryId,
      'GroupId': groupId,
      'Rate': rate,
      'RateIncludingTax': rateIncludingTax,
      'GrossAmount': grossAmount,
      'GrossAmountIncludingTax': grossAmountIncludingTax,
      'DiscountPercent': discountPercent,
      'Discount': discount,
      'DiscountIncludingTax': discountIncludingTax,
      'DiscountType': discountType,
      'OfferId': offerId,
      'IsCombo': isCombo,
      'IsMaintainBatchLotNo': isMaintainBatchLotNo,
      'IsNonConversableUnit': isNonConversableUnit,
      'Taxable': taxable,
      'NonTaxable': nonTaxable,
      'TaxPercent': taxPercent,
      'TaxAmount': taxAmount,
      'NetAmount': netAmount,
      'SalesInvoiceItemTax': salesInvoiceItemTax
          .map((e) => e.toJson())
          .toList(),
      'Barcode': barcode,
      'HSCode': hsCode,
      'Attribute1': attribute1,
      'Attribute2': attribute2,
    };
  }
}

class SalesInvoiceItemTaxRequest {
  final int taxOrder;
  final String name;
  final String taxType;
  final double tax;
  final double taxableAmount;
  final double taxAmount;
  final double netAmount;

  SalesInvoiceItemTaxRequest({
    this.taxOrder = 1,
    this.name = 'VAT SALES',
    this.taxType = 'Percent',
    this.tax = 13,
    this.taxableAmount = 0,
    this.taxAmount = 0,
    this.netAmount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'TaxOrder': taxOrder,
      'Name': name,
      'TaxType': taxType,
      'Tax': tax,
      'TaxableAmount': taxableAmount,
      'TaxAmount': taxAmount,
      'NetAmount': netAmount,
    };
  }
}

class SalesInvoicePaymentRequest {
  final String payMode;
  final String paymentId;
  final double amount;
  final String roomId;
  final String roomGuestName;
  final String roomNumber;

  SalesInvoicePaymentRequest({
    required this.payMode,
    required this.paymentId,
    required this.amount,
    this.roomId = '',
    this.roomGuestName = '',
    this.roomNumber = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'PayMode': payMode,
      'PaymentId': paymentId,
      'Amount': amount,
      'RoomId': roomId,
      'RoomGuestName': roomGuestName,
      'RoomNumber': roomNumber,
    };
  }
}
