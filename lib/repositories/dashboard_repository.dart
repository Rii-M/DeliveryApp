import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../models/category.dart';
import '../models/driver.dart';
import '../models/driver_stock.dart';
import '../models/product.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    db: ref.read(databaseServiceProvider).db,
  );
});

class DashboardRepository {
  final Database _db;

  DashboardRepository({
    required this._db,
  });

  Future<Driver?> getDriver() async {
    final maps = await _db.query('driver', limit: 1);
    if (maps.isEmpty) return null;
    return Driver.fromMap(maps.first);
  }

  Future<int> getTodaysDeliveries() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM delivery WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getEstimatedBillsCreated() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM estimate WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getPendingSyncCount() async {
    final result = await _db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'Pending'",
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

  Future<void> saveDriver(Driver driver) async {
    await _db.insert('driver', driver.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveCategories(List<Category> categories) async {
    final batch = _db.batch();
    for (final cat in categories) {
      batch.insert('category', cat.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveProducts(List<Product> products) async {
    final batch = _db.batch();
    for (final prod in products) {
      batch.insert('product', prod.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<int> getTodaysSalesReturns() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM sales_return WHERE created_date >= ? AND created_date < ?',
      [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAssignedCustomersCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM customer');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAssignedProductsCount() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM product');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getRemainingAssignedStock() async {
    final result = <Map<String, dynamic>>[];
    final stockMaps = await _db.query('driver_stock');
    if (stockMaps.isEmpty) return result;

    final stockList = stockMaps.map((m) => DriverStock.fromMap(m)).toList();
    final productIds = stockList.map((s) => s.productId).toList();
    final placeholders = List.generate(productIds.length, (_) => '?').join(',');
    final productMaps = await _db.query('product',
        where: 'server_id IN ($placeholders)', whereArgs: productIds);
    final productMap = {
      for (final m in productMaps) m['server_id'] as String: Product.fromMap(m)
    };

    for (final stock in stockList) {
      final product = productMap[stock.productId];
      if (product != null) {
        result.add({
          'product': product,
          'assigned': stock.assignedQuantity,
          'delivered': stock.deliveredQuantity,
          'remaining': stock.remainingQuantity,
        });
      }
    }
    return result;
  }

  Future<void> saveDriverStock(List<DriverStock> stockList) async {
    final batch = _db.batch();
    for (final stock in stockList) {
      batch.insert('driver_stock', stock.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Returns the customer sync queue entries (with customer name/phone) so the
  /// dashboard can show "synced / not synced" status along with any sync error.
  Future<List<Map<String, dynamic>>> getCustomerSyncStatus() async {
    final maps = await _db.rawQuery('''
      SELECT q.id AS queue_id, q.entity_type, q.entity_id, q.status,
             q.created_date, q.error_message,
             c.name AS customer_name, c.phone AS customer_phone
      FROM sync_queue q
      LEFT JOIN customer c ON c.id = q.entity_id
      WHERE q.entity_type = 'Customer'
      ORDER BY q.created_date ASC
    ''');
    return maps;
  }
}

