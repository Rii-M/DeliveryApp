import 'dart:convert';

import 'product_unit.dart';

class Product {
  int? id;
  late String serverId;
  late String categoryId;
  late String name;
  String? japaneseName;
  String? code;
  late double unitPrice;
  double stock = 0;
  String? unitId;
  String? unit;
  String? imageUrl;
  List<String> productImages = [];
  String? description;
  int taxable = 0;
  String? chalanId;
  String? chalanNumber;
  List<ProductUnit> units = [];

  Product();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'category_id': categoryId,
      'name': name,
      'japanese_name': japaneseName,
      'unit_price': unitPrice,
      'stock': stock,
      'unit_id': unitId,
      'unit': unit,
      'image_url': imageUrl,
      'product_images': productImages.isNotEmpty
          ? jsonEncode(productImages)
          : null,
      'description': description,
      'taxable': taxable,
      'chalan_id': chalanId,
      'chalan_number': chalanNumber,
      'units_json': units.isNotEmpty ? jsonEncode(units.map((u) => u.toJson()).toList()) : null,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final product = Product();
    product.id = map['id'] as int?;
    product.serverId = map['server_id'] as String;
    product.categoryId = map['category_id'] as String;
    product.name = map['name'] as String;
    product.japaneseName = map['japanese_name'] as String?;
    product.unitPrice = (map['unit_price'] as num).toDouble();
    product.stock = (map['stock'] as num?)?.toDouble() ?? 0;
    product.unitId = map['unit_id'] as String?;
    product.unit = map['unit'] as String?;
    product.imageUrl = map['image_url'] as String?;
    product.description = map['description'] as String?;
    product.taxable = (map['taxable'] as num?)?.toInt() ?? 0;
    product.chalanId = map['chalan_id'] as String?;
    product.chalanNumber = map['chalan_number'] as String?;
    final imagesRaw = map['product_images'] as String?;
    if (imagesRaw != null && imagesRaw.isNotEmpty) {
      product.productImages = (jsonDecode(imagesRaw) as List).cast<String>();
    }
    final unitsRaw = map['units_json'] as String?;
    if (unitsRaw != null && unitsRaw.isNotEmpty) {
      product.units = (jsonDecode(unitsRaw) as List)
          .map((e) => ProductUnit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return product;
  }

  String localizedName(String languageCode) {
    if (languageCode == 'ne' && japaneseName != null && japaneseName!.isNotEmpty) {
      return japaneseName!;
    }
    return name;
  }

  String? get firstImageUrl =>
      productImages.isNotEmpty ? productImages.first : imageUrl;
}
