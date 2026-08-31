import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/customer_discount_group.dart';

final discountGroupRepositoryProvider =
    Provider<DiscountGroupRepository>((ref) {
  return DiscountGroupRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class DiscountGroupRepository {
  final ApiService _apiService;
  final Database _db;

  DiscountGroupRepository({required this._apiService, required Database db})
      : _db = db;

  /// Offline-first: returns locally cached discount groups when available and
  /// falls back to a network fetch (and caches the result) when the cache is
  /// empty.
  Future<List<CustomerDiscountGroup>> getDiscountGroups() async {
    final cached = await getCachedDiscountGroups();
    if (cached.isNotEmpty) return cached;
    return refreshFromServer();
  }

  Future<List<CustomerDiscountGroup>> getCachedDiscountGroups() async {
    final maps = await _db.query(
      'customer_discount_group',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps
        .map((map) => CustomerDiscountGroup(
              id: (map['server_id'] ?? '').toString(),
              recordId: (map['record_id'] ?? '').toString(),
              name: (map['name'] ?? '').toString(),
              discountPercent: ((map['discount_percent'] ?? 0) as num)
                  .toDouble(),
              isActive: (map['is_active'] ?? 1) == 1,
            ))
        .toList();
  }

  /// Fetches discount groups from the server and refreshes the local cache.
  Future<List<CustomerDiscountGroup>> refetch() {
    return refreshFromServer();
  }

  Future<List<CustomerDiscountGroup>> refreshFromServer() async {
    final data = await _apiService.fetchCustomerDiscountGroups();
    final groups = data
        .map(CustomerDiscountGroup.fromJson)
        .where((g) => g.isActive)
        .toList();
    if (groups.isNotEmpty) {
      await _db.delete('customer_discount_group');
      final batch = _db.batch();
      for (final g in groups) {
        batch.insert(
          'customer_discount_group',
          {
            'server_id': g.id,
            'record_id': g.recordId,
            'name': g.name,
            'discount_percent': g.discountPercent,
            'is_active': g.isActive ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
    return groups;
  }
}

final discountGroupNameProvider = FutureProvider.family<String?, String>(
  (ref, groupId) async {
    final groups = await ref
        .watch(discountGroupRepositoryProvider)
        .getCachedDiscountGroups();
    return groups.where((g) => g.id == groupId).firstOrNull?.name;
  },
);