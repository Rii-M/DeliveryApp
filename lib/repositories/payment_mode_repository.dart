import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/payment_mode.dart';

final paymentModeRepositoryProvider = Provider<PaymentModeRepository>((ref) {
  return PaymentModeRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class PaymentModeRepository {
  final ApiService _apiService;
  final Database _db;

  PaymentModeRepository({required this._apiService, required Database db})
      : _db = db;

  Future<List<PaymentMode>> getPaymentModes() async {
    final maps = await _db.query('payment_mode');
    return maps.map((map) => PaymentMode.fromMap(map)).toList();
  }

  Future<void> savePaymentModes(List<PaymentMode> paymentModes) async {
    final batch = _db.batch();
    for (final mode in paymentModes) {
      batch.insert('payment_mode', mode.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> refreshPaymentModes() async {
    final modes = await fetchPaymentModesFromApi();
    if (modes.isNotEmpty) {
      await _db.delete('payment_mode');
      final batch = _db.batch();
      for (final mode in modes) {
        batch.insert('payment_mode', mode.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<List<PaymentMode>> fetchPaymentModesFromApi() async {
    final data = await _apiService.fetchPaymentModes();
    return data.map((json) {
      final mode = PaymentMode();
      mode.serverId = json['Id'] as String;
      mode.name = json['Name'] as String;
      mode.tempId = json['TempId'] as int;
      return mode;
    }).toList();
  }
}
