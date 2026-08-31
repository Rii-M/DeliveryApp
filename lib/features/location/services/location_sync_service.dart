import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'location_database_service.dart';
import 'location_api_service.dart';

class LocationSyncService {
  final LocationDatabaseService _db = LocationDatabaseService();
  final LocationApiService _api;
  final Connectivity _connectivity = Connectivity();
  bool _isSyncing = false;
  Timer? _timer;

  LocationSyncService(this._api);

  void startPeriodicSync({Duration interval = const Duration(minutes: 1)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => sync());
  }

  void stopPeriodicSync() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    final online = await isOnline();
    if (!online) return;

    _isSyncing = true;
    try {
      final unsynced = await _db.getUnsyncedLocations();
      if (unsynced.isEmpty) return;

      if (kDebugMode) print('Syncing ${unsynced.length} locations...');

      final batch = unsynced.map((r) => r.toJson()).toList();
      await _api.sendBatch(batch);

      final ids = unsynced.map((r) => r.id!).toList();
      await _db.markAsSynced(ids);
      await _db.clearSyncedLocations();

      if (kDebugMode) print('Synced ${ids.length} locations successfully');
    } catch (e) {
      if (kDebugMode) print('Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}