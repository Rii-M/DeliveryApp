import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/category_wise_discount.dart';

final categoryWiseDiscountRepositoryProvider =
    Provider<CategoryWiseDiscountRepository>((ref) {
  return CategoryWiseDiscountRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CategoryWiseDiscountRepository {
  final ApiService _apiService;
  final Database _db;

  CategoryWiseDiscountRepository({
    required this._apiService,
    required Database db,
  }) : _db = db;

  /// Returns all cached category-wise discount rules from local storage.
  Future<List<CategoryWiseDiscount>> getCachedRules() async {
    final maps = await _db.query('category_wise_discount');
    return maps.map((map) => CategoryWiseDiscount.fromMap(map)).toList();
  }

  /// Fetches category-wise discounts from the server and refreshes the local
  /// cache using the project's full-refresh master-data pattern.
  Future<List<CategoryWiseDiscount>> refreshFromServer() async {
    final data = await _apiService.fetchCategoryWiseDiscounts();
    final rules = data.map(CategoryWiseDiscount.fromJson).toList();
    if (rules.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('category_wise_discount');
        for (final r in rules) {
          await txn.insert(
            'category_wise_discount',
            r.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    }
    return rules;
  }

  /// Finds a category-wise discount rule for a customer discount group and
  /// product category. Returns null when no record exists so a rule with
  /// DiscountPercent = 0 stays distinct from "no rule".
  Future<CategoryWiseDiscount?> getDiscountRule({
    required String customerDiscountGroupId,
    required String categoryId,
  }) async {
    final maps = await _db.query(
      'category_wise_discount',
      where: 'customer_discount_group_id = ? AND category_id = ?',
      whereArgs: [customerDiscountGroupId, categoryId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CategoryWiseDiscount.fromMap(maps.first);
  }

  /// Effective discount percent for a customer discount group + product
  /// category, computed from local data only. A matching rule wins (including
  /// an explicit 0%), otherwise the group's default discount percent is used.
  Future<double> getDiscountPercent({
    required String customerDiscountGroupId,
    required String categoryId,
  }) async {
    final rule = await getDiscountRule(
      customerDiscountGroupId: customerDiscountGroupId,
      categoryId: categoryId,
    );
    if (rule != null) return rule.discountPercent;
    return getGroupDefaultPercent(customerDiscountGroupId);
  }

  /// Default discount percent of a customer discount group (0 when missing).
  Future<double> getGroupDefaultPercent(String customerDiscountGroupId) async {
    final maps = await _db.query(
      'customer_discount_group',
      where: 'server_id = ?',
      whereArgs: [customerDiscountGroupId],
      limit: 1,
    );
    if (maps.isEmpty) return 0;
    return ((maps.first['discount_percent'] ?? 0) as num).toDouble();
  }
}
