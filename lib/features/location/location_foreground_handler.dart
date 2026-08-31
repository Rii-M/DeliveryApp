import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'models/location_record.dart';
import 'services/location_database_service.dart';
import 'services/location_sync_service.dart';
import 'services/location_api_service.dart';
import 'package:dio/dio.dart';

@pragma('vm:entry-point')
void startLocationTrackingCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTrackingTaskHandler());
}

class LocationTrackingTaskHandler extends TaskHandler {
  Timer? _periodicTimer;
  StreamSubscription<Position>? _positionStream;
  final LocationDatabaseService _db = LocationDatabaseService();
  LocationSyncService? _syncService;
  String _driverId = '';

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      final data = await FlutterForegroundTask.getData<String>(key: 'driverId');
      _driverId = data ?? '';

      final baseUrl = await FlutterForegroundTask.getData<String>(key: 'baseUrl');
      final token = await FlutterForegroundTask.getData<String>(key: 'token');

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl ?? '',
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token ?? ''}',
        },
      ));
      final apiService = LocationApiService(dio);
      _syncService = LocationSyncService(apiService);

      _startPositionStream();

      _periodicTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) async {
          try {
            final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );
            _handlePosition(pos);
          } catch (_) {}
        },
      );

      if (kDebugMode) print('Foreground: tracking initialized');
    } catch (e) {
      if (kDebugMode) print('Foreground init error: $e');
    }
  }

  Future<void> _startPositionStream() async {
    await _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) => _handlePosition(pos),
      onError: (_) {
        Future.delayed(const Duration(seconds: 5), _startPositionStream);
      },
      cancelOnError: false,
    );
  }

  Future<void> _handlePosition(Position pos) async {
    final record = LocationRecord(
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestamp: DateTime.now(),
      accuracy: pos.accuracy,
      speed: pos.speed,
      driverId: _driverId,
    );

    await _db.insertLocation(record);

    if (kDebugMode) {
      print('Foreground: saved location (${pos.latitude}, ${pos.longitude})');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _periodicTimer?.cancel();
    await _positionStream?.cancel();
    _syncService?.stopPeriodicSync();
    _syncService?.dispose();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onRepeatEvent(DateTime timestamp) {}
}
