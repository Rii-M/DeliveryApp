import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/customer_group.dart';

final customerGroupRepositoryProvider = Provider<CustomerGroupRepository>((ref) {
  return CustomerGroupRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CustomerGroupRepository {
  final ApiService _apiService;
  final Database _db;

  CustomerGroupRepository({required this._apiService, required Database db})
      : _db = db;

  /// Offline-first: returns locally cached customer groups when available and
  /// falls back to a network fetch (and caches the result) when the cache is
  /// empty.
  Future<List<CustomerGroup>> getCustomerGroups() async {
    final cached = await getCachedCustomerGroups();
    if (cached.isNotEmpty) return cached;
    return refreshFromServer();
  }

  Future<List<CustomerGroup>> getCachedCustomerGroups() async {
    final maps = await _db.query(
      'customer_group',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps
        .map((map) => CustomerGroup(
              id: (map['server_id'] ?? '').toString(),
              recordId: (map['record_id'] ?? '').toString(),
              name: (map['name'] ?? '').toString(),
              isActive: (map['is_active'] ?? 1) == 1,
            ))
        .toList();
  }

  /// Fetches customer groups from the server and refreshes the local cache.
  Future<List<CustomerGroup>> refetch() {
    return refreshFromServer();
  }

  Future<List<CustomerGroup>> refreshFromServer() async {
    final data = await _apiService.fetchCustomerGroups();
    final groups = data
        .map(CustomerGroup.fromJson)
        .where((g) => g.isActive)
        .toList();
    if (groups.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('customer_group');
        for (final g in groups) {
          await txn.insert(
            'customer_group',
            {
              'server_id': g.id,
              'record_id': g.recordId,
              'name': g.name,
              'is_active': g.isActive ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
    return groups;
  }
}