import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import 'models/location_record.dart';
import 'services/location_service.dart';
import 'services/location_database_service.dart';
import 'services/location_sync_service.dart';
import 'services/location_api_service.dart';
import '../../core/network/providers.dart';
import '../../features/auth/provider/auth_provider.dart';
import 'location_foreground_handler.dart';

final locationServiceProvider = Provider((_) => LocationService());
final locationDatabaseServiceProvider = Provider((_) => LocationDatabaseService());
final locationSyncServiceProvider = Provider((ref) => LocationSyncService(ref.read(locationApiServiceProvider)));
final locationApiServiceProvider = Provider((ref) => LocationApiService(ref.read(dioProvider)));

final locationStateProvider = StateNotifierProvider<LocationStateNotifier, LocationState>((ref) {
  final authState = ref.watch(authProvider);
  return LocationStateNotifier(
    ref.read(locationServiceProvider),
    ref.read(locationDatabaseServiceProvider),
    ref.read(locationSyncServiceProvider),
    initialDriverId: authState.driverId,
    initialBaseUrl: authState.baseUrl,
    initialToken: authState.finalToken,
  );
});

class LocationState {
  final Position? currentPosition;
  final List<LocationRecord> recentLocations;
  final bool isTracking;
  final int pendingSyncCount;
  final bool isOnline;
  final String? error;
  final String? driverId;

  const LocationState({
    this.currentPosition,
    this.recentLocations = const [],
    this.isTracking = false,
    this.pendingSyncCount = 0,
    this.isOnline = false,
    this.error,
    this.driverId,
  });

  LocationState copyWith({
    Position? currentPosition,
    List<LocationRecord>? recentLocations,
    bool? isTracking,
    int? pendingSyncCount,
    bool? isOnline,
    String? error,
    String? driverId,
  }) =>
      LocationState(
        currentPosition: currentPosition ?? this.currentPosition,
        recentLocations: recentLocations ?? this.recentLocations,
        isTracking: isTracking ?? this.isTracking,
        pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
        isOnline: isOnline ?? this.isOnline,
        error: error,
        driverId: driverId ?? this.driverId,
      );
}

class LocationStateNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;
  final LocationDatabaseService _db;
  final String? _driverId;
  final String? _baseUrl;
  final String? _token;
  final LocationSyncService _syncService;
  Timer? _uiRefreshTimer;

  LocationStateNotifier(
    this._locationService,
    this._db,
    this._syncService, {
    String? initialDriverId,
    String? initialBaseUrl,
    String? initialToken,
  }) : _driverId = initialDriverId,
       _baseUrl = initialBaseUrl,
       _token = initialToken,
       super(LocationState(driverId: initialDriverId)) {
    _init();
  }

  Future<void> _init() async {
    final online = await _syncService.isOnline();
    final pending = await _db.getPendingCount();
    final existingLocations = await _db.getAllLocations();
    state = state.copyWith(isOnline: online, pendingSyncCount: pending, recentLocations: existingLocations);

   bool serviceRunning = false;
    try {
      serviceRunning = await FlutterForegroundTask.isRunningService;
    } catch (_) {}
    if (serviceRunning) {
      state = state.copyWith(isTracking: true);
      _startUiRefresh();
    }

    _syncService.startPeriodicSync();
  }

  void _startUiRefresh() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!state.isTracking) return;
      final pending = await _db.getPendingCount();
      final online = await _syncService.isOnline();
      if (mounted) {
        state = state.copyWith(pendingSyncCount: pending, isOnline: online);
      }
    });
  }

  void _stopUiRefresh() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = null;
  }

  Future<void> startTracking() async {
    state = state.copyWith(error: null);

    final locationPermission = await _locationService.requestPermission();
    if (!locationPermission) {
      state = state.copyWith(error: 'Location permission denied');
      return;
    }

    final notificationPermission = await FlutterForegroundTask.requestNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      state = state.copyWith(error: 'Notification permission denied. Please enable it in Settings.');
      return;
    }

    try {
      final serviceRunning = await FlutterForegroundTask.isRunningService;
      if (serviceRunning) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}

    await FlutterForegroundTask.saveData(
      key: 'driverId',
      value: _driverId ?? '',
    );
    await FlutterForegroundTask.saveData(
      key: 'baseUrl',
      value: _baseUrl ?? '',
    );
    await FlutterForegroundTask.saveData(
      key: 'token',
      value: _token ?? '',
    );

    final startResult = await FlutterForegroundTask.startService(
      notificationTitle: 'Location Tracking',
      notificationText: 'Tracking your location during duty',
      callback: startLocationTrackingCallback,
    );

    if (startResult is ServiceRequestSuccess) {
      state = state.copyWith(isTracking: true, error: null);
      _startUiRefresh();
    } else {
      final errorMsg = (startResult is ServiceRequestFailure)
          ? 'Failed to start: ${startResult.error}'
          : 'Failed to start background tracking';
      state = state.copyWith(error: errorMsg);
    }
  }

  Future<void> stopTracking() async {
    _stopUiRefresh();

    await FlutterForegroundTask.stopService();

    state = state.copyWith(isTracking: false);

    if (await _syncService.isOnline()) {
      await _syncService.sync();
      final pending = await _db.getPendingCount();
      state = state.copyWith(pendingSyncCount: pending);
    }
  }

  Future<void> manualSync() async {
    state = state.copyWith(error: null);
    final online = await _syncService.isOnline();
    state = state.copyWith(isOnline: online);
    if (online) {
      await _syncService.sync();
      final pending = await _db.getPendingCount();
      state = state.copyWith(pendingSyncCount: pending);
    } else {
      state = state.copyWith(error: 'No internet connection');
    }
  }

  @override
  void dispose() {
    _stopUiRefresh();
    _syncService.dispose();
    super.dispose();
  }
}
