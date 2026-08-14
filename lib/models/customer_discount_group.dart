class CustomerDiscountGroup {
  final String id;
  final String recordId;
  final String name;
  final double discountPercent;
  final bool isActive;

  CustomerDiscountGroup({
    required this.id,
    required this.recordId,
    required this.name,
    required this.discountPercent,
    required this.isActive,
  });

  factory CustomerDiscountGroup.fromJson(Map<String, dynamic> json) {
    return CustomerDiscountGroup(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      recordId: (json['RecordId'] ?? json['recordId'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      discountPercent:
          (json['DiscountPercent'] ?? json['discountPercent'] ?? 0).toDouble(),
      isActive: (json['IsActive'] ?? json['isActive'] ?? false) == true,
    );
  }
}