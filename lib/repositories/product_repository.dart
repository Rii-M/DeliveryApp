
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:convert';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/product.dart';
import '../models/product_unit.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class ProductRepository {
  final ApiService _apiService;
  final Database _db;

  ProductRepository({required this._apiService, required Database db})
    : _db = db;

  Future<List<Product>> getProducts({
    required String customerId,
    required String transactionDate,
  }) async {
    final cached = await _db.query('product');
    if (cached.isNotEmpty) {
      return cached.map((map) => Product.fromMap(map)).toList();
    }
    return _fetchAndCacheProducts(
      deliveryBoyId: customerId,
      transactionDate: transactionDate,
    );
  }

  Future<List<Product>> refreshProducts({
    required String customerId,
    required String transactionDate,
  }) async {
    return _fetchAndCacheProducts(
      deliveryBoyId: customerId,
      transactionDate: transactionDate,
    );
  }

  Future<List<Product>> getCachedProducts() async {
    final maps = await _db.query('product');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> refreshAllProducts() async {
    final data = await _apiService.fetchAllProducts();
    final products = data.map((json) {
      final p = Product();
      p.serverId = json['ProductId']?.toString() ?? '';
      p.categoryId = json['CategoryId']?.toString() ?? '';
      p.name = json['Name']?.toString() ?? '';
      p.code = json['Code']?.toString();
      p.japaneseName = json['JapaneseName']?.toString() ?? json['JapneseName']?.toString();
      p.imageUrl = json['ImagePath']?.toString();
      p.unitId = json['BaseUnitId']?.toString();
      p.unit = json['BaseUnitName']?.toString();
      p.unitPrice = (json['Rate'] as num?)?.toDouble() ?? 0;
      p.taxable = (json['Taxable'] as num?)?.toInt() ?? 0;

      final unitsRaw = json['Units'] as List?;
      if (unitsRaw != null) {
        p.units = unitsRaw
            .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return p;
    }).toList();

    if (products.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('all_product');
        for (final p in products) {
          await txn.insert('all_product', {
            'server_id': p.serverId,
            'code': p.code,
            'category_id': p.categoryId,
            'name': p.name,
            'japanese_name': p.japaneseName,
            'unit_id': p.unitId,
            'unit': p.unit,
            'unit_price':p.unitPrice,
            'image_url': p.imageUrl,
            'units_json': p.units.isNotEmpty ? jsonEncode(p.units.map((u) => u.toJson()).toList()) : null,
            'taxable': p.taxable,
            'chalan_id': p.chalanId,
            'chalan_number': p.chalanNumber,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    }

    return products;
  }

  Future<List<Product>> getCachedAllProducts() async {
    final maps = await _db.query('all_product');
    return maps.map((map) {
      final p = Product();
      p.serverId = map['server_id'] as String;
      p.code = map['code'] as String?;
      p.categoryId = map['category_id'] as String;
      p.name = map['name'] as String;
      p.japaneseName = map['japanese_name'] as String?;
      p.unitId = map['unit_id'] as String?;
      p.unit = map['unit'] as String?;
      p.imageUrl = map['image_url'] as String?;
      p.unitPrice = (map['unit_price'] as num?)?.toDouble() ?? 0;
      p.taxable = (map['taxable'] as int?) ?? 0;
      p.chalanId = map['chalan_id'] as String?;
      p.chalanNumber = map['chalan_number'] as String?;
      final unitsRaw = map['units_json'] as String?;
      if (unitsRaw != null && unitsRaw.isNotEmpty) {
        p.units = (jsonDecode(unitsRaw) as List)
            .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return p;
    }).toList();
  }

 Future<List<Product>> _fetchAndCacheProducts({
    required String deliveryBoyId,
    required String transactionDate,
  }) async {
    final data = await _apiService.fetchProducts(
      deliveryBoyId: deliveryBoyId,
      transactionDate: transactionDate,
    );

    Product productFromJson(Map<String, dynamic> json) {
      final p = Product();
      p.serverId = json['ProductId'] as String;
      p.categoryId = json['CategoryId'] as String;
      p.name = json['Name'] as String;
      p.japaneseName = json['JapaneseName'] as String?;
      p.unitPrice = (json['Rate'] as num?)?.toDouble() ?? 0;
      p.stock = (json['Quantity'] as num?)?.toDouble() ?? 0;
      p.taxable = (json['Taxable'] as num?)?.toInt() ?? 0;
      p.chalanId = json['ChalanId'] as String?;
      p.chalanNumber = json['ChalanNumber'] as String?;
      p.customerId = json['CustomerId'] as String?;

      final baseUnit = json['BaseUnit'] as Map<String, dynamic>?;
      if (baseUnit != null) {
        p.unitId = baseUnit['UnitId'] as String?;
        p.unit = baseUnit['UnitName'] as String?;
      }

      final unitsRaw = json['Units'] as List?;
      if (unitsRaw != null) {
        p.units = unitsRaw
            .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      final rawImages = json['ImagePaths'] as List?;
      if (rawImages != null) {
        p.productImages = rawImages.map((e) {
          if (e is String) return e;
          return e.toString();
        }).toList();
        if (p.productImages.isNotEmpty && p.imageUrl == null) {
          p.imageUrl ??= p.productImages.first;
        }
      }

      return p;
    }

    // The API returns one row per chalan/assignment line, so the same product
    // may appear multiple times. Merge rows that share (ProductId, Rate, UnitId)
    // by summing their quantity; keep separate rows when the rate or unit
    // differs so each variant can be delivered independently.
    final merged = <String, Product>{};
    for (final json in data) {
      final p = productFromJson(json);
      final key = '${p.serverId}|${p.unitPrice}|${p.unitId}';
      final existing = merged[key];
      if (existing == null) {
        merged[key] = p;
      } else {
        existing.stock += p.stock;
      }
    }
    final products = merged.values.toList();

    if (products.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('product');
        for (final p in products) {
          await txn.insert(
            'product',
            p.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } else {
      await _db.delete('product');
    }

    return products;
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final maps = await _db.query(
      'product',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  /// Resolves the product row(s) for a server product id. When a variant
  /// discriminator (unitPrice/unitId) is given, rows matching it are preferred;
  /// otherwise it falls back to the first row sharing the server id so existing
  /// callers keep working after a product is split into multiple variants.
  Future<List<Map<String, Object?>>> _findVariants(
    String productId, {
    double? unitPrice,
    String? unitId,
  }) async {
    var where = 'server_id = ?';
    final args = <Object?>[productId];
    if (unitPrice != null) {
      where += ' AND unit_price = ?';
      args.add(unitPrice);
    }
    if (unitId != null && unitId.isNotEmpty) {
      where += ' AND unit_id = ?';
      args.add(unitId);
    }
    var maps = await _db.query('product', where: where, whereArgs: args);
    if (maps.isEmpty &&
        (unitPrice != null || (unitId != null && unitId.isNotEmpty))) {
      maps = await _db.query('product',
          where: 'server_id = ?', whereArgs: [productId]);
    }
    return maps;
  }

  Future<void> restoreStock(
    String productId,
    double quantity, {
    double? unitPrice,
    String? unitId,
  }) async {
    final maps =
        await _findVariants(productId, unitPrice: unitPrice, unitId: unitId);
    if (maps.isEmpty) return;
    final rowId = maps.first['id'] as int;
    final currentStock = (maps.first['stock'] as num?)?.toDouble() ?? 0;
    final newStock = currentStock + quantity;
    await _db.update(
      'product',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }

  Future<void> deductStock(
    String productId,
    double quantity, {
    double? unitPrice,
    String? unitId,
  }) async {
    final maps =
        await _findVariants(productId, unitPrice: unitPrice, unitId: unitId);
    if (maps.isEmpty) return;
    final rowId = maps.first['id'] as int;
    final currentStock = (maps.first['stock'] as num?)?.toDouble() ?? 0;
    final newStock = currentStock - quantity;
    final effectiveStock = (newStock).clamp(0, double.infinity);
    await _db.update(
      'product',
      {'stock': effectiveStock},
      where: 'id = ?',
      whereArgs: [rowId],
    );
  }
}
