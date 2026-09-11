import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../models/location_record.dart';

class LocationDatabaseService {
  static Database? _db;
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
  }

  Future<Database> get database async {
    await _ensureInitialized();
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'location_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE locations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            timestamp TEXT NOT NULL,
            accuracy REAL,
            speed REAL,
            synced INTEGER DEFAULT 0,
            driverId TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_synced ON locations(synced)');
      },
    );
  }

  Future<int> insertLocation(LocationRecord record) async {
    final db = await database;
    return db.insert('locations', record.toMap()..remove('id'));
  }

  Future<List<LocationRecord>> getUnsyncedLocations() async {
    final db = await database;
    final maps = await db.query('locations', where: 'synced = 0', orderBy: 'id ASC');
    return maps.map((m) => LocationRecord.fromMap(m)).toList();
  }

  Future<List<LocationRecord>> getAllLocations({int limit = 100}) async {
    final db = await database;
    final maps = await db.query('locations', orderBy: 'id DESC', limit: limit);
    return maps.map((m) => LocationRecord.fromMap(m)).toList();
  }

  Future<void> markAsSynced(List<int> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('locations', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM locations WHERE synced = 0');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> clearSyncedLocations() async {
    final db = await database;
    await db.delete('locations', where: 'synced = 1');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}