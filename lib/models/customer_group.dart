class CustomerGroup {
  final String id;
  final String recordId;
  final String name;
  final bool isActive;

  CustomerGroup({
    required this.id,
    required this.recordId,
    required this.name,
    required this.isActive,
  });

  factory CustomerGroup.fromJson(Map<String, dynamic> json) {
    return CustomerGroup(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      recordId: (json['RecordId'] ?? json['recordId'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      isActive: (json['IsActive'] ?? json['isActive'] ?? false) == true,
    );
  }
}