import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/auth/auth_storage.dart';
import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/customer.dart';
import '../models/sync_queue.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CustomerRepository {
  final ApiService _apiService;
  final Database _db;

  CustomerRepository({
    required this._apiService,
    required Database db,
  })  : _db = db;

  static String _getField(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) return value.toString();
    }
    return '';
  }

  Customer _customerFromJson(Map<String, dynamic> json) {
    return Customer()
      ..serverId = _getField(json, ['Id', 'id', 'server_id'])
      ..recordId = _getField(json, ['RecordId', 'recordId'])
      ..name = _getField(json, ['Name', 'name'])
      ..phone = _getField(json, ['Mobile', 'phone'])
      ..address = _getField(json, ['Address', 'address'])
      ..email = _getField(json, ['Email', 'email'])
      ..pan = _getField(json, ['PAN', 'Pan', 'pan'])
      ..discountGroupId =
          _getField(json, ['CustomerDiscountGroupId', 'discountGroupId'])
      ..areaId = _getField(json, ['AreaId', 'areaId'])
      ..customerGroupId =
          _getField(json, ['CustomerGroupId', 'customerGroupId'])
      ..isActive = (json['IsActive'] ?? json['isActive'] ?? true) == true
      ..isAllowCredit =
          (json['IsAllowCredit'] ?? json['isAllowCredit'] ?? true) == true
      ..isSynced = true
      ..pendingAction = null;
  }

  Future<List<Customer>> getCustomers() async {
    final cached = await _db.query('customer');
    if (cached.isNotEmpty) {
      return cached.map((map) => Customer.fromMap(map)).toList();
    }
    return _fetchAndCacheCustomers();
  }

  /// Downloads customers from the server into local cache, preserving any
  /// locally-created unsynced rows.
  Future<List<Customer>> refreshCustomers() async {
    final data = await _apiService.fetchCustomers(await getSavedDriverId() ?? '');
    final customers = data.map(_customerFromJson).toList();

    if (customers.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('customer', where: 'is_synced = ?', whereArgs: [1]);
        for (final c in customers) {
          txn.insert('customer', c.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }

    return customers;
  }

  Future<List<Customer>> _fetchAndCacheCustomers() {
    return refreshCustomers();
  }

  Future<List<Customer>> getCachedCustomers() async {
    final maps = await _db.query('customer',
        where: 'is_synced = ?', whereArgs: [1]);
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  /// Locally added/edited customers that have NOT yet been confirmed by the
  /// server. These are hidden from pickers and only surfaced in the
  /// sync-status screen until they are synced.
  Future<List<Customer>> getPendingCustomers() async {
    final maps = await _db.query('customer',
        where: 'is_synced = ?', whereArgs: [0]);
    return maps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(String serverId) async {
    final maps = await _db.query('customer',
        where: 'server_id = ?', whereArgs: [serverId]);
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Checks whether any customer on the server already uses the given mobile
  /// number. When [excludeCustomerId] is provided, that customer is skipped so
  /// editing the SAME customer doesn't false-positive.
  Future<bool> isMobileTakenOnServer(
    String mobile, {
    String? excludeCustomerId,
  }) async {
    final trimmed = mobile.trim();
    if (trimmed.isEmpty) return false;
    final data = await _apiService.fetchCustomers(await getSavedDriverId() ?? '');
    for (final json in data) {
      final serverMobile = _getField(json, ['Mobile', 'mobile']).trim();
      if (serverMobile.isEmpty || serverMobile != trimmed) continue;
      final id = _getField(json, ['Id', 'id']);
      final recordId = _getField(json, ['RecordId', 'recordId']);
      if (excludeCustomerId != null &&
          (id == excludeCustomerId || recordId == excludeCustomerId)) {
        continue;
      }
      return true;
    }
    return false;
  }

  /// Saves a brand new customer locally (offline-first) and queues it for
  /// sync. Returns the stored customer with the local id assigned.
  Future<Customer> saveNewCustomerOffline({
    required String name,
    required String mobile,
    String? email,
    String? address,
    String? pan,
    required String discountGroupId,
    String? areaId,
    String? customerGroupId,
  }) async {
    final customer = Customer()
      ..serverId = _generateTempId()
      ..name = name
      ..phone = mobile
      ..email = email
      ..address = address
      ..pan = pan
      ..discountGroupId = discountGroupId
      ..areaId = areaId
      ..customerGroupId = customerGroupId
      ..metaData = '{"ContactPersons":[]}'
      ..isActive = true
      ..isAllowCredit = true
      ..isSynced = false
      ..pendingAction = 'Add';

    final id = await _db.transaction((txn) async {
      final customerId = await txn.insert('customer', customer.toMap());
      final syncEntry = SyncQueue()
        ..entityType = 'Customer'
        ..entityId = customerId
        ..status = 'Pending'
        ..createdDate = DateTime.now()
        ..customerName = customer.name
        ..customerPhone = customer.phone;
      await txn.insert('sync_queue', syncEntry.toMap());
      return customerId;
    });
    customer.id = id;
    return customer;
  }

  /// Updates an existing customer locally (offline-first) and queues it for
  /// sync. Keeps the pending action as 'Add' if the customer was created
  /// offline and has not been synced yet.
  Future<Customer> updateCustomerOffline({
    required String serverId,
    required String name,
    required String mobile,
    String? email,
    String? address,
    String? pan,
    required String discountGroupId,
    String? areaId,
    String? customerGroupId,
  }) async {
    final maps = await _db.query('customer',
        where: 'server_id = ?', whereArgs: [serverId], limit: 1);
    if (maps.isEmpty) {
      throw Exception('Customer not found');
    }
    final existing = Customer.fromMap(maps.first);
    final wasSynced = existing.isSynced;
    existing
      ..name = name
      ..phone = mobile
      ..email = email
      ..address = address
      ..pan = pan
      ..discountGroupId = discountGroupId
      ..areaId = areaId
      ..customerGroupId = customerGroupId
      ..isSynced = false;
    if (wasSynced) {
      existing.pendingAction = 'Update';
    }

    await _db.transaction((txn) async {
      await txn.update(
        'customer',
        existing.toMap(),
        where: 'server_id = ?',
        whereArgs: [serverId],
      );
      final existingSync = await txn.query(
        'sync_queue',
        where: 'entity_type = ? AND entity_id = ?',
        whereArgs: ['Customer', existing.id],
      );
      if (existingSync.isEmpty) {
        final syncEntry = SyncQueue()
          ..entityType = 'Customer'
          ..entityId = existing.id!
          ..status = 'Pending'
          ..createdDate = DateTime.now()
          ..customerName = existing.name
          ..customerPhone = existing.phone;
        await txn.insert('sync_queue', syncEntry.toMap());
      }
    });

    return existing;
  }

  String _generateTempId() {
    final rng = Random();
    final hex = List.generate(32, (_) => rng.nextInt(16).toRadixString(16));
    return '${hex.sublist(0, 8).join()}-'
        '${hex.sublist(8, 12).join()}-'
        '4${hex.sublist(13, 16).join()}-'
        '${(8 + rng.nextInt(4)).toRadixString(16)}${hex.sublist(17, 20).join()}-'
        '${hex.sublist(20).join()}';
  }
}
