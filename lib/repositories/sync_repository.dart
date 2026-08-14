import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_config.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../core/utils/tax_calculator.dart';
import '../dto/sales_invoice_request.dart';
import '../dto/customer_operation_result.dart';
import '../core/auth/auth_storage.dart';
import '../dto/sales_return_request.dart';
import '../models/customer.dart';
import '../models/estimate.dart';
import '../models/sales_return.dart';
import '../models/sync_queue.dart';
import '../models/payment_entry.dart';

class SyncRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;
  String _outletId;

  SyncRepository({
    required this._apiService,
    required Database db,
    required this._networkChecker,
    required String outletId,
  })  : _db = db,
        _outletId = outletId;

    void updateOutletId(String outletId) {
     _outletId = outletId;
    }

  Future<List<SyncQueue>> getPendingQueue() async {
    final maps = await _db.rawQuery(
      "SELECT * FROM sync_queue WHERE status != 'Synced' ORDER BY created_date ASC",
    );
    return maps.map((m) => SyncQueue.fromMap(m)).toList();
  }

  Future<int> getPendingCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Pending'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Failed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getSyncedCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Synced'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<DateTime?> getLastSyncTime() async {
    final maps = await _db.rawQuery(
      "SELECT * FROM sync_queue WHERE status = 'Synced' ORDER BY created_date DESC LIMIT 1",
    );
    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['created_date'] as String);
  }

  Future<bool> syncAll() async {
    final isOnline = await _networkChecker.isConnected;
    if (!isOnline) return false;

    await _db.update(
      'sync_queue',
      {'status': 'Pending'},
      where: "status = 'Syncing'",
    );

    final pending = await getPendingQueue();

    for (final entry in pending) {
      try {
        await _db.update(
          'sync_queue',
          {'status': 'Syncing'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );

        if (entry.entityType == 'Delivery') {
          await _syncDeliveryEntry(entry);
        } else if (entry.entityType == 'SalesReturn') {
          await _syncSalesReturnEntry(entry);
        } else if (entry.entityType == 'Customer') {
          await _syncCustomerEntry(entry);
        } else {
          await _db.update(
            'sync_queue',
            {'status': 'Failed'},
            where: 'id = ?',
            whereArgs: [entry.id],
          );
        }
      } catch (_) {
        await _db.update(
          'sync_queue',
          {'status': 'Failed'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
    }

    return true;
  }

  Future<void> _syncDeliveryEntry(SyncQueue entry) async {
    final deliveryMaps = await _db.query('delivery',
        where: 'id = ?', whereArgs: [entry.entityId]);
    if (deliveryMaps.isEmpty) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return;
    }

    final estimateMaps = await _db.query('estimate',
        where: 'delivery_id = ?', whereArgs: [entry.entityId]);
    if (estimateMaps.isEmpty) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return;
    }
    final driverId = await getSavedDriverId() ?? '';
    final driverName = await getSavedDriverName() ?? '';  // first name
    final estimate = Estimate.fromMap(estimateMaps.first);
    final customerId = deliveryMaps.first['customer_id'] as String?;

    final itemMaps = await _db.query('estimate_item',
        where: 'estimate_id = ?', whereArgs: [estimate.id]);
    final items = itemMaps.map((m) => EstimateItem.fromMap(m)).toList();

    final productMaps = await _db.query('product');
    final productsMap = <String, Map<String, dynamic>>{
      for (final p in productMaps) (p['server_id'] as String): p,
    };

    final paymentModeMaps = await _db.query('payment_mode');
    final payModeName = estimate.paymentMode != null
        ? (paymentModeMaps.cast<Map<String, dynamic>?>().firstWhere(
              (m) => m?['server_id'] == estimate.paymentMode,
              orElse: () => null,
            )?['name'] as String? ?? 'Cash')
        : 'Cash';
    
    List<PaymentEntry> paymentEntries = estimate.paymentEntries;
    if (paymentEntries.isEmpty && estimate.paymentMode != null && estimate.paidAmount > 0) {
      paymentEntries = [
        PaymentEntry(
          paymentModeId: estimate.paymentMode,
          paymentModeName: payModeName,
          amount: estimate.paidAmount,
        ),
      ];
    }

    final now = estimate.createdDate;
    final transactionDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final totalQty = items.fold<double>(0, (sum, i) => sum + i.quantity);
    final globalDiscount = estimate.discountAmount;

    final salesInvoiceItems = items.map((item) {
      final product = productsMap[item.productId];

      final tax = computeItemTax(
        rate: item.unitPrice,
        quantity: item.quantity,
        discount: item.discountAmount,
        taxableType: (product?['taxable'] as num?)?.toInt() ?? 0,
      );


      return SalesInvoiceItemRequest(
        refNo: item.productId,
        chalanNumber: product?['chalan_number'] as String? ?? '',
        productId: item.productId,
        name: product?['name'] as String? ?? '',
        quantity: item.quantity,
        unitId: item.unitId ?? product?['unit_id'] as String? ?? '',
        unitName: item.unitName ?? product?['unit'] as String? ?? '',
        categoryId: product?['category_id'] as String? ?? ApiConfig.emptyGuid,
        rate: tax.rateExTax,
        rateIncludingTax: tax.rateIncTax,
        grossAmount: tax.grossAmount,
        grossAmountIncludingTax: tax.grossAmountIncTax,
        discount: tax.discountExcTax,
        discountIncludingTax: tax.discountIncludingTax,
        taxable: tax.taxableAmount,
        nonTaxable: tax.nonTaxableAmount,
        taxPercent: kDefaultTaxPercent,
        taxAmount: tax.taxAmount,
        netAmount: tax.netAmount,
        salesInvoiceItemTax: [
          SalesInvoiceItemTaxRequest(
            taxableAmount: tax.taxableAmount,
            taxAmount: tax.taxAmount,
            netAmount: tax.netAmount,
          ),
        ],
      );
    }).toList();

    final totalTaxable = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.taxable);
    final totalNonTaxable = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.nonTaxable);
    final totalItemTax = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.taxAmount);
    final totalDiscountExcTax =
        salesInvoiceItems.fold<double>(
            0, (sum, item) => sum + item.discount) +
        globalDiscount;
    final totalDiscountIncludingTax =
        salesInvoiceItems.fold<double>(
            0, (sum, item) => sum + item.discountIncludingTax) +
        globalDiscount;
    final totalGrossAmountExcTax = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.grossAmount,
    );
    final totalGrossAmountIncTax = salesInvoiceItems.fold<double>(
        0, (sum, item) => sum + item.grossAmountIncludingTax,
    );
    final totalNetAmount = totalGrossAmountIncTax - totalDiscountIncludingTax;

    final chalanNumber = items.isNotEmpty
        ? (productsMap[items.first.productId]?['chalan_number'] as String? ?? '')
        : '';

    
      String customerName = '';
    final customerMaps = await _db.query(
      'customer',
      where: 'server_id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (customerMaps.isNotEmpty) {
      customerName = customerMaps.first['name'] as String? ?? '';
    }

    final request = SalesInvoiceRequest(
      chalanNumber: chalanNumber,
      transactionDate: transactionDate,
      customerId: customerId,
      customerName: customerName,
      outletId: _outletId,
      deliveryBoyId: driverId,
      deliveryBoyName: driverName,
      totalQuantity: totalQty,
      totalGrossAmount: totalGrossAmountExcTax,
      totalGrossAmountIncludingTax: totalGrossAmountIncTax,
      totalDiscount: totalDiscountExcTax,
      totalDiscountIncludingTax: totalDiscountIncludingTax,
      totalTaxableAmount: totalTaxable,
      totalNonTaxableAmount: totalNonTaxable,
      totalTax: totalItemTax,
      totalNetAmount: totalNetAmount,
      totalPayableAmount: totalNetAmount,
      payMode: paymentEntries.length == 1
          ? (paymentEntries.first.paymentModeName ?? 'Cash')
          : 'Mix',
      tenderAmount: totalNetAmount,
      salesInvoiceTax: [
        SalesInvoiceTaxRequest(taxAmount: totalItemTax),
      ],
      salesInvoiceItem: salesInvoiceItems,
      // salesInvoicePayment: [
      //   SalesInvoicePaymentRequest(
      //     payMode: payModeName,
      //     paymentId: estimate.paymentMode ?? ApiConfig.emptyGuid,
      //     amount: estimate.paidAmount > 0 ? estimate.paidAmount : totalNetAmount,
      //   ),
      // ],
      salesInvoicePayment: paymentEntries.map((entry) =>
        SalesInvoicePaymentRequest(
          payMode: entry.paymentModeName ?? 'Cash',
          paymentId: entry.paymentModeId ?? ApiConfig.emptyGuid,
          amount: entry.amount,
        ),
      ).toList(),
      currencyId: ApiConfig.defaultCurrencyId,
    );

    final response = await _apiService.createSalesInvoice(request);

    if (response.success) {
      await _db.update(
        'estimate',
        {'server_id': response.invoiceId, 'is_synced': 1},
        where: 'id = ?',
        whereArgs: [estimate.id],
      );
      await _db.update(
        'delivery',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [estimate.deliveryId],
      );
      await _db.update(
        'sync_queue',
        {'status': 'Synced'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } else {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  Future<void> _syncSalesReturnEntry(SyncQueue entry) async {
    final maps = await _db
        .query('sales_return', where: 'id = ?', whereArgs: [entry.entityId]);
    if (maps.isEmpty) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return;
    }
    final sr = SalesReturn.fromMap(maps.first);
    final driverId = await getSavedDriverId() ?? '';
    final driverName = await getSavedDriverName() ?? '';

    final itemMaps = await _db.query('sales_return_item',
        where: 'sales_return_id = ?', whereArgs: [sr.id]);
    sr.items = itemMaps.map((m) => SalesReturnItem.fromMap(m)).toList();

    // Look up product details from product table
    final productMaps = await _db.query('all_product');
    final productsMap = <String, Map<String, dynamic>>{
      for (final p in productMaps) (p['server_id'] as String): p,
    };

    // Calculate tax breakdown for each item
    final salesInvoiceItems = <SalesInvoiceItemRequest>[];
    double totalQty = 0;
    double totalGrossAmount = 0;
    double totalGrossAmountIncTax = 0;
    double totalDiscountExcTax = 0;
    double totalDiscountIncTax = 0;
    double totalTaxableAmount = 0;
    double totalNonTaxableAmount = 0;
    double totalTaxAmount = 0;
    double totalNetAmount = 0;

    for (final item in sr.items) {
      final product = productsMap[item.productId];
      final taxableType = item.taxable;

      final tax = computeItemTax(
        rate: item.rate,
        quantity: item.quantity,
        discount: item.discountAmount,
        taxableType: taxableType,
        taxPercent: kDefaultTaxPercent,
      );

      final itemRequest = SalesInvoiceItemRequest(
        sku: product?['code'] as String?,
        hasSerialNumber: false,
        serialNumber: '',
        refNo: item.productId,
        chalanNumber: product?['chalan_number'] as String? ?? '',
        lotNo: '',
        productId: item.productId,
        name: item.productName,
        quantity: item.quantity,
        unitId: item.unitId ?? product?['unit_id'] as String? ?? '',
        unitName: item.unit ?? product?['unit'] as String? ?? '',
        categoryId: product?['category_id'] as String? ?? ApiConfig.emptyGuid,
        groupId: product?['category_id'] as String? ?? ApiConfig.emptyGuid,
        rate: tax.rateExTax,
        rateIncludingTax: tax.rateIncTax,
        grossAmount: tax.grossAmount,
        grossAmountIncludingTax: tax.grossAmountIncTax,
        discountPercent: 0,
        discount: tax.discountExcTax,
        discountIncludingTax: tax.discountIncludingTax,
        discountType: 'Product',
        offerId: '',
        isCombo: false,
        isMaintainBatchLotNo: false,
        isNonConversableUnit: false,
        taxable: tax.taxableAmount,
        nonTaxable: tax.nonTaxableAmount,
        taxPercent: kDefaultTaxPercent,
        taxAmount: tax.taxAmount,
        netAmount: tax.netAmount,
        salesInvoiceItemTax: [
          SalesInvoiceItemTaxRequest(
            taxOrder: 1,
            name: 'VAT SALES',
            taxType: 'Percent',
            tax: kDefaultTaxPercent,
            taxableAmount: tax.taxableAmount,
            taxAmount: tax.taxAmount,
            netAmount: tax.netAmount,
          ),
        ],
        barcode: '',
        hsCode: '',
        attribute1: '',
        attribute2: '',
      );

      salesInvoiceItems.add(itemRequest);

      totalQty += item.quantity;
      totalGrossAmount += tax.grossAmount;
      totalGrossAmountIncTax += tax.grossAmountIncTax;
      totalDiscountExcTax += tax.discountExcTax;
      totalDiscountIncTax += tax.discountIncludingTax;
      totalTaxableAmount += tax.taxableAmount;
      totalNonTaxableAmount += tax.nonTaxableAmount;
      totalTaxAmount += tax.taxAmount;
      totalNetAmount += tax.netAmount;
    }

    // Add header discount to totals
    totalDiscountExcTax += sr.discountAmount;
    totalDiscountIncTax += sr.discountAmount;
    totalNetAmount -= sr.discountAmount;

    // Build payment entries
    final salesInvoicePayments = <SalesInvoicePaymentRequest>[];
    for (final entry in sr.paymentEntries) {
      final payModeName = entry.paymentModeName ?? 'Cash';
      final payModeId = entry.paymentModeId ?? ApiConfig.emptyGuid;
      salesInvoicePayments.add(SalesInvoicePaymentRequest(
        payMode: payModeName,
        paymentId: payModeId,
        amount: entry.amount,
      ));
    }

    // Build transaction date from createdDate
    final now = sr.createdDate;
    final transactionDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    // Look up customer name from customer table
    String customerName = '';
    final customerMaps = await _db.query(
      'customer',
      where: 'server_id = ?',
      whereArgs: [sr.customerId],
      limit: 1,
    );
    if (customerMaps.isNotEmpty) {
      customerName = customerMaps.first['name'] as String? ?? '';
    }

    // Build the request
    final request = SalesReturnRequest(
      transactionDate: transactionDate,
      transactionDateBS: '',
      type: 'Return',
      isReturn: true,
      isSettled: true,
      customerId: sr.customerId,
      customerName: customerName,
      remarks: sr.reason ?? sr.remarks ?? '',
      outletId: _outletId,
      deliveryBoyId: driverId,
      deliveryBoyName: driverName,
      totalQuantity: totalQty,
      totalGrossAmount: totalGrossAmount,
      totalGrossAmountIncludingTax: totalGrossAmountIncTax,
      totalDiscount: totalDiscountExcTax,
      totalDiscountIncludingTax: totalDiscountIncTax,
      totalTaxableAmount: totalTaxableAmount,
      totalNonTaxableAmount: totalNonTaxableAmount,
      totalTax: totalTaxAmount,
      totalNetAmount: totalNetAmount,
      totalPayableAmount: totalNetAmount,
      currencyName: 'NRs',
      payMode: sr.paymentMode ?? 'Cash',
      tenderAmount: totalNetAmount,
      changeAmount: 0,
      salesInvoiceTax: [
        SalesInvoiceTaxRequest(
          taxOrder: 1,
          name: 'VAT SALES',
          taxAmount: totalTaxAmount,
        ),
      ],
      salesInvoiceItem: salesInvoiceItems,
      salesInvoicePayment: salesInvoicePayments,
      currencyId: ApiConfig.defaultCurrencyId,
      volumeDiscount: sr.discountAmount,
    );

    try {
      final json = request.toJson();
      print('[Sync] OutletId=${json['OutletId']} CustomerId=${json['CustomerId']} CustomerName=[${json['CustomerName']}] CurrencyId=${json['CurrencyId']} PayMode=${json['PayMode']}');
      print('[Sync] Item[0]=${jsonEncode(json['SalesInvoiceItem']?.first)}');
      print('[Sync] Payment=${jsonEncode(json['SalesInvoicePayment'])}');
      final response = await _apiService.createSalesReturnV2(request);
      print('[Sync] SalesReturnV2 response: $response');
      if (response) {
        await _db.update(
          'sales_return',
          {'is_synced': 1},
          where: 'id = ?',
          whereArgs: [sr.id],
        );
        await _db.update(
          'sync_queue',
          {'status': 'Synced'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      } else {
        print('[Sync] SalesReturnV2 FAILED - server returned Status: false');
        await _db.update(
          'sync_queue',
          {'status': 'Failed'},
          where: 'id = ?',
          whereArgs: [entry.id],
        );
      }
    } catch (e) {
      print('[Sync] SalesReturnV2 ERROR: $e');
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    }
  }

  /// Pushes a single queued customer to the server immediately if online.
  /// Used right after saving a customer while connected so no manual
  /// "Sync All" is needed. Offline saves stay queued. Returns true when the
  /// server accepted the customer; false when it was rejected/failed.
  Future<bool> syncCustomerById(int customerId) async {
    final isOnline = await _networkChecker.isConnected;
    if (!isOnline) return false;

    final maps = await _db.query(
      'sync_queue',
      where: 'entity_type = ? AND entity_id = ? AND status != ?',
      whereArgs: ['Customer', customerId, 'Synced'],
    );
    if (maps.isEmpty) return true;
    var allOk = true;
    for (final map in maps) {
      final entry = SyncQueue.fromMap(map);
      try {
        if (!await _syncCustomerEntry(entry)) allOk = false;
      } catch (_) {
        allOk = false;
      }
    }
    return allOk;
  }

  Future<bool> _syncCustomerEntry(SyncQueue entry) async {
    final maps = await _db.query(
      'customer',
      where: 'id = ?',
      whereArgs: [entry.entityId],
    );
    if (maps.isEmpty) {
      await _markCustomerSyncFailed(entry, 'Customer record not found');
      return false;
    }
    final customer = Customer.fromMap(maps.first);
    final isUpdate = customer.pendingAction == 'Update' &&
        customer.recordId != null &&
        customer.recordId!.isNotEmpty;

    // Before adding, ensure the mobile number isn't already used on the server
    // by a DIFFERENT customer. (Server only enforces name/email uniqueness.)
    if (!isUpdate && customer.phone != null && customer.phone!.trim().isNotEmpty) {
      final exists = await _isMobileUsedServerSide(
        customer.phone!.trim(),
        excludeCustomerId: isUpdate
            ? (customer.recordId ?? customer.serverId)
            : null,
      );
      if (exists) {
        print(
            '[Sync] Customer ${customer.name} NOT added - mobile ${customer.phone} already exists on server');
        await _discardRejectedCustomer(
          customer,
          'mobile ${customer.phone} already exists on server',
        );
        return false;
      }
    }

    final payload = _buildCustomerPayload(customer, forUpdate: isUpdate);

    final CustomerOperationResult result;
    if (isUpdate) {
      print('[Sync] Updating customer ${customer.name} (${customer.recordId})');
      result = await _apiService.updateCustomer(payload, customer.recordId!);
    } else {
      print('[Sync] Adding customer ${customer.name}');
      result = await _apiService.addCustomer(payload);
    }

    if (result.success) {
      await _db.update(
        'customer',
        {'is_synced': 1, 'pending_action': null},
        where: 'id = ?',
        whereArgs: [customer.id],
      );
      await _db.update(
        'sync_queue',
        {'status': 'Synced', 'error_message': null},
        where: 'id = ?',
        whereArgs: [entry.id],
      );
      return true;
    } else {
      print('[Sync] Customer sync FAILED - server returned Status: false');
      if (!isUpdate) {
        await _discardRejectedCustomer(customer, result.message);
      } else {
        await _markCustomerSyncFailed(
          entry,
          result.message.isNotEmpty ? result.message : 'Customer sync failed',
        );
      }
      return false;
    }
  }

  /// Removes a locally-added customer that the server permanently rejected
  /// (e.g. duplicate mobile / Status false) along with its queued sync entry so
  /// it no longer appears anywhere in the app. A record is kept in
  /// rejected_customer_log so the driver can see that the customer was not saved.
  Future<void> _discardRejectedCustomer(
    Customer customer,
    String reason,
  ) async {
    await _db.transaction((txn) async {
      await txn.delete('customer', where: 'id = ?', whereArgs: [customer.id]);
      await txn.delete(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Customer', customer.id],
      );
      await txn.insert('rejected_customer_log', {
        'name': customer.name,
        'phone': customer.phone,
        'reason': reason,
        'created_date': DateTime.now().toIso8601String(),
      });
    });
    print('[Sync] Discarded rejected customer ${customer.name} - $reason');
  }

  Future<void> _markCustomerSyncFailed(SyncQueue entry, String message) async {
    await _db.update(
      'sync_queue',
      {'status': 'Failed', 'error_message': message},
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Checks the server customer list for a row already using this mobile. When
  /// [excludeCustomerId] is given, that customer is skipped so editing the same
  /// customer doesn't false-positive.
  Future<bool> _isMobileUsedServerSide(
    String mobile, {
    String? excludeCustomerId,
  }) async {
    final data = await _apiService.fetchCustomers();
    for (final json in data) {
      final serverMobile =
          (json['Mobile'] ?? json['mobile'] ?? '').toString().trim();
      if (serverMobile.isEmpty || serverMobile != mobile) continue;
      final id = (json['Id'] ?? json['id'] ?? '').toString();
      final recordId =
          (json['RecordId'] ?? json['recordId'] ?? '').toString();
      if (excludeCustomerId != null &&
          (id == excludeCustomerId || recordId == excludeCustomerId)) {
        continue;
      }
      return true;
    }
    return false;
  }

  Map<String, dynamic> _buildCustomerPayload(
    Customer c, {
    required bool forUpdate,
  }) {
    return {
      if (forUpdate) 'Id': c.serverId,
      if (forUpdate) 'RecordId': c.recordId,
      'Name': c.name,
      'Mobile': c.phone,
      'Email': c.email,
      'Address': c.address,
      'PAN': c.pan,
      'CustomerDiscountGroupId': c.discountGroupId ?? ApiConfig.emptyGuid,
      'AgentId': null,
      'ClassName': null,
      'Code': null,
      'CreditLimit': 0,
      'DOB': null,
      'IsActive': c.isActive,
      'IsAllowCredit': c.isAllowCredit,
      'MappedBranchId': null,
      'MappedDepartmentId': null,
      'MetaData': c.metaData ?? '{"ContactPersons":[]}',
      'ReferenceBranchId': null,
      'ReferredBy': null,
      'SetAsSupplier': false,
    };
  }
}

