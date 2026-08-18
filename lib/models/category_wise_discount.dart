class CategoryWiseDiscount {
  int? id;
  late String serverId;
  String? recordId;
  late String categoryId;
  late String customerDiscountGroupId;
  double discountPercent = 0;

  CategoryWiseDiscount();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'record_id': recordId,
      'category_id': categoryId,
      'customer_discount_group_id': customerDiscountGroupId,
      'discount_percent': discountPercent,
    };
  }

  factory CategoryWiseDiscount.fromMap(Map<String, dynamic> map) {
    final rule = CategoryWiseDiscount();
    rule.id = map['id'] as int?;
    rule.serverId = map['server_id'] as String;
    rule.recordId = map['record_id'] as String?;
    rule.categoryId = map['category_id'] as String;
    rule.customerDiscountGroupId =
        map['customer_discount_group_id'] as String;
    rule.discountPercent = (map['discount_percent'] as num?)?.toDouble() ?? 0;
    return rule;
  }

  factory CategoryWiseDiscount.fromJson(Map<String, dynamic> json) {
    return CategoryWiseDiscount()
      ..serverId = (json['Id'] ?? json['id'] ?? '').toString()
      ..recordId = (json['RecordId'] ?? json['recordId'] ?? '').toString()
      ..categoryId = (json['CategoryId'] ?? json['categoryId'] ?? '').toString()
      ..customerDiscountGroupId = (json['CustomerDiscountGroupId'] ??
              json['customerDiscountGroupId'] ??
              '')
          .toString()
      ..discountPercent =
          (json['DiscountPercent'] ?? json['discountPercent'] ?? 0).toDouble();
  }
}
