import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/providers.dart';
import '../core/network/api_service.dart';
import '../core/network/providers.dart';
import '../models/category.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    apiService: ref.read(apiServiceProvider),
    db: ref.read(databaseServiceProvider).db,
  );
});

class CategoryRepository {
  final ApiService _apiService;
  final Database _db;

  CategoryRepository({
    required this._apiService,
    required Database db,
  })  : _db = db;

  Future<List<Category>> getCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    final cached = await _db.query('category');
    if (cached.isNotEmpty) {
      return cached.map((map) => Category.fromMap(map)).toList();
    }
    return _fetchAndCacheCategories(
      customerId: customerId,
      transactionDate: transactionDate,
    );
  }

  Future<List<Category>> refreshCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    return _fetchAndCacheCategories(
      customerId: customerId,
      transactionDate: transactionDate,
    );
  }

  Future<List<Category>> getCachedCategories() async {
    final maps = await _db.query('category');
    return maps.map((map) => Category.fromMap(map)).toList();
  }

  Future<List<Category>> _fetchAndCacheCategories({
    required String customerId,
    required String transactionDate,
  }) async {
    final data = await _apiService.fetchCategories(
      customerId: customerId,
      transactionDate: transactionDate,
    );
    final categories = data.map((json) {
      final cat = Category();
      cat.serverId = json['CategoryId'] as String;
      cat.name = json['Name'] as String;
      cat.japaneseName = json['JapaneseName'] as String?;
      final rawImageList = json['ImagePaths'] as List?;
      if (rawImageList != null) {
        cat.imageList = rawImageList.map((e) {
          if (e is String) return e;
          return e.toString();
        }).toList();
        if (cat.imageList.isNotEmpty) {
          cat.imageUrl ??= cat.imageList.first;
        }
      }
      return cat;
    }).toList();

    if (categories.isNotEmpty) {
      await _db.transaction((txn) async {
        await txn.delete('category');
        for (final c in categories) {
          await txn.insert('category', c.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } else {
      await _db.delete('category');
    }

    return categories;
  }

  Future<List<Category>> getAssignedCategories() async {
  try {
    final data = await _apiService.fetchAssignedCategories();
    return data.map((json) {
      final cat = Category();
      cat.serverId = json['categoryId']?.toString() ?? '';
      cat.name = json['name']?.toString() ?? '';
      cat.japaneseName = json['japaneseName']?.toString();
      final image = json['imagePath']?.toString();
      if (image != null && image.isNotEmpty) {
        cat.imageUrl = image;
        cat.imageList = [image];
      }
      return cat;
    }).toList();
  } catch (e) {
    // Offline fallback: use whatever the last sync cached, so delivery/sync
    // behavior is untouched and this never throws.
    return getCachedCategories();
  }
}

}
