class Area {
  final String id;
  final String recordId;
  final String name;
  final bool isActive;

  Area({
    required this.id,
    required this.recordId,
    required this.name,
    required this.isActive,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      recordId: (json['RecordId'] ?? json['recordId'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      isActive: (json['IsActive'] ?? json['isActive'] ?? false) == true,
    );
  }
}
