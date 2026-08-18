import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/area.dart';

final areaRepositoryProvider = Provider<AreaRepository>((ref) {
  return AreaRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class AreaRepository {
  final ApiService _apiService;
  final Database _db;

  AreaRepository({required this._apiService, required Database db}) : _db = db;

  /// Offline-first: returns locally cached areas when available and falls back
  /// to a network fetch (and caches the result) when the cache is empty.
  Future<List<Area>> getAreas() async {
    final cached = await getCachedAreas();
    if (cached.isNotEmpty) return cached;
    return refreshFromServer();
  }

  Future<List<Area>> getCachedAreas() async {
    final maps = await _db.query(
      'area',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps
        .map((map) => Area(
              id: (map['server_id'] ?? '').toString(),
              recordId: (map['record_id'] ?? '').toString(),
              name: (map['name'] ?? '').toString(),
              isActive: (map['is_active'] ?? 1) == 1,
            ))
        .toList();
  }

  /// Fetches areas from the server and refreshes the local cache.
  Future<List<Area>> refetch() {
    return refreshFromServer();
  }

  Future<List<Area>> refreshFromServer() async {
    final data = await _apiService.fetchAreas();
    final areas = data.map(Area.fromJson).where((a) => a.isActive).toList();
    if (areas.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('area');
        for (final a in areas) {
          await txn.insert(
            'area',
            {
              'server_id': a.id,
              'record_id': a.recordId,
              'name': a.name,
              'is_active': a.isActive ? 1 : 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
    return areas;
  }
}
