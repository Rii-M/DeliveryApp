import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../models/delivery.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(
    db: ref.read(databaseServiceProvider).db,
  );
});

class DeliveryRepository {
  final Database _db;

  DeliveryRepository({
    required this._db,
  });

  Future<Delivery> updateDelivery(
    int deliveryId, {
    required String customerId,
    required List<DeliveryItem> items,
    String? paymentMode,
  }) async {
    final delivery = Delivery()
      ..id = deliveryId
      ..customerId = customerId
      ..createdDate = DateTime.now()
      ..paymentMode = paymentMode
      ..isSynced = false;

    await _db.transaction((txn) async {
      await txn.update(
        'delivery',
        delivery.toMap(),
        where: 'id = ?',
        whereArgs: [deliveryId],
      );

      await txn.delete('delivery_item',
          where: 'delivery_id = ?', whereArgs: [deliveryId]);

      for (final item in items) {
        item.deliveryId = deliveryId;
        await txn.insert('delivery_item', item.toMap());
      }

      final existingSync = await txn.query('sync_queue',
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', deliveryId]);
      if (existingSync.isNotEmpty) {
        await txn.update(
          'sync_queue',
          {'status': 'Synced'},
          where: 'entity_type = ? AND entity_id = ?',
          whereArgs: ['Delivery', deliveryId],
        );
      }
    });

    return delivery;
  }

  Future<Delivery> saveDelivery({
    required String customerId,
    required List<DeliveryItem> items,
    String? paymentMode,
  }) async {
    final delivery = Delivery()
      ..customerId = customerId
      ..createdDate = DateTime.now()
      ..paymentMode = paymentMode
      ..isSynced = false;

    final id = await _db.transaction((txn) async {
      final deliveryId = await txn.insert('delivery', delivery.toMap());
      for (final item in items) {
        item.deliveryId = deliveryId;
        await txn.insert('delivery_item', item.toMap());
      }
      return deliveryId;
    });
    delivery.id = id;

    return delivery;
  }
  
  Future<void> markSynced(int deliveryId, String serverId) async {
    await _db.update(
      'delivery',
      {'is_synced': 1, 'server_id': serverId},
      where: 'id = ?',
      whereArgs: [deliveryId],
    );
}

  Future<List<Delivery>> getDeliveriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await _db.query('delivery',
        where: 'created_date >= ? AND created_date < ?',
        whereArgs: [
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String()
        ],
        orderBy: 'created_date DESC');
    return maps.map((m) => Delivery.fromMap(m)).toList();
  }

  Future<List<Delivery>> getPendingDeliveries() async {
    final maps = await _db
        .query('delivery', where: 'is_synced = ?', whereArgs: [0]);
    return maps.map((m) => Delivery.fromMap(m)).toList();
  }

  Future<Delivery?> getDeliveryById(int id) async {
    final maps =
        await _db.query('delivery', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Delivery.fromMap(maps.first);
  }

  Future<List<DeliveryItem>> getDeliveryItems(int deliveryId) async {
    final maps = await _db.query('delivery_item',
        where: 'delivery_id = ?', whereArgs: [deliveryId]);
    return maps.map((m) => DeliveryItem.fromMap(m)).toList();
  }
}

