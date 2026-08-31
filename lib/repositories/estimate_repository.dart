import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/network_checker.dart';
import '../core/network/providers.dart';
import '../dto/sales_invoice_request.dart';
import '../models/estimate.dart';
import '../models/sync_queue.dart';
import '../models/payment_entry.dart';

final estimateRepositoryProvider = Provider<EstimateRepository>((ref) {
  return EstimateRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
    networkChecker: ref.read(networkCheckerProvider),
  );
});

class EstimateRepository {
  final ApiService _apiService;
  final Database _db;
  final NetworkChecker _networkChecker;

  EstimateRepository({
    required this._apiService,
    required Database db,
    required this._networkChecker,
  }) : _db = db;

  Future<Estimate> saveEstimate({
    required int deliveryId,
    required List<EstimateItem> items,
    String? paymentMode,
    double? paidAmount,
    String? remarks,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    List<PaymentEntry> paymentEntries = const [],
    SalesInvoiceRequest? salesInvoiceRequest,
  }) async {
    final grossTotal = items.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final netTotal = grossTotal - (discountAmount ?? 0);

    final estimate = Estimate()
      ..deliveryId = deliveryId
      ..grossTotal = grossTotal
      ..estimatedTotal = netTotal
      ..discountType = discountType
      ..discountValue = discountValue ?? 0
      ..discountAmount = discountAmount ?? 0
      ..paymentMode = paymentMode
      ..paidAmount = paidAmount ?? 0
      ..remarks = remarks
      ..paymentEntries = paymentEntries
      ..createdDate = DateTime.now()
      ..isSynced = false;

    final id = await _db.transaction((txn) async {
      final estimateId = await txn.insert('estimate', estimate.toMap());
      for (final item in items) {
        item.estimateId = estimateId;
        await txn.insert('estimate_item', item.toMap());
      }
      final syncEntry = SyncQueue()
        ..entityType = 'Delivery'
        ..entityId = deliveryId
        ..status = 'Pending'
        ..createdDate = DateTime.now();
      await txn.insert('sync_queue', syncEntry.toMap());
      return estimateId;
    });
    estimate.id = id;

    final isOnline = await _networkChecker.isConnected;
    if (isOnline && salesInvoiceRequest != null) {
      await _syncSalesInvoice(salesInvoiceRequest, id, deliveryId);
    }

    return estimate;
  }

  Future<void> _syncSalesInvoice(
    SalesInvoiceRequest request,
    int estimateId,
    int deliveryId,
  ) async {
    await _db.update(
      'sync_queue',
      {'status': 'Syncing'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['Delivery', deliveryId],
    );

    try {
      final response = await _apiService.createSalesInvoice(request);
      final invoiceId = response.invoiceId;
      if (response.success && invoiceId != null) {
        final transactionId = int.tryParse(invoiceId);
        if (transactionId != null) {
          await _pollTransactionStatus(transactionId, estimateId, deliveryId);
        } else {
          await _markSynced(estimateId, deliveryId, invoiceId);
        }
      } else {
        await _db.update(
          'sync_queue',
          {'status': 'Failed'},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', deliveryId],
        );
      }
    } catch (_) {
      await _db.update(
        'sync_queue',
        {'status': 'Failed'},
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Delivery', deliveryId],
      );
    }
  }

  Future<void> _pollTransactionStatus(
    int transactionId,
    int estimateId,
    int deliveryId,
  ) async {
    const maxAttempts = 30;
    const pollInterval = Duration(seconds: 2);

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        final status = await _apiService.getTransactionStatus(transactionId);
        if (status.state == 1) {
          await _markSynced(estimateId, deliveryId, transactionId.toString());
          return;
        } else if (status.state == 2) {
          print('[POLL] Transaction $transactionId failed: ${status.message}');
          await _db.update(
            'sync_queue',
            {'status': 'Failed'},
            where: 'entity_type = ? AND entity_id = ?',
            whereArgs: ['Delivery', deliveryId],
          );
          return;
        }
        // state == 0: still processing, wait and retry
      } catch (e) {
        print('[POLL] Error checking transaction $transactionId: $e');
      }
      await Future.delayed(pollInterval);
    }

    print('[POLL] Transaction $transactionId timed out after $maxAttempts attempts');
    await _markSynced(estimateId, deliveryId, transactionId.toString());
  }

  Future<void> _markSynced(int estimateId, int deliveryId, String serverId) async {
    await _db.update(
      'estimate',
      {'server_id': serverId, 'is_synced': 1},
      where: 'id = ?',
      whereArgs: [estimateId],
    );
    await _db.update(
      'sync_queue',
      {'status': 'Synced'},
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: ['Delivery', deliveryId],
    );
    await _db.update(
      'delivery',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [deliveryId],
    );
  }

  Future<List<Estimate>> getEstimatesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query(
      'estimate',
      where: 'created_date >= ? AND created_date < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'created_date DESC',
    );
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }

  Future<List<Estimate>> getEstimatesByDelivery(int deliveryId) async {
    final maps = await _db.query(
      'estimate',
      where: 'delivery_id = ?',
      whereArgs: [deliveryId],
    );
    return maps.map((m) => Estimate.fromMap(m)).toList();
  }

  Future<List<EstimateItem>> getEstimateItems(int estimateId) async {
    final maps = await _db.query(
      'estimate_item',
      where: 'estimate_id = ?',
      whereArgs: [estimateId],
    );
    return maps.map((m) => EstimateItem.fromMap(m)).toList();
  }
}
