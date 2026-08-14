class CustomerArea {
  final String id;
  final String recordId;
  final String name;
  final bool isActive;

  CustomerArea({
    required this.id,
    required this.recordId,
    required this.name,
    required this.isActive,
  });

  factory CustomerArea.fromJson(Map<String, dynamic> json) {
    return CustomerArea(
      id: (json['Id'] ?? json['id'] ?? '').toString(),
      recordId: (json['RecordId'] ?? json['recordId'] ?? '').toString(),
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      isActive: (json['IsActive'] ?? json['isActive'] ?? false) == true,
    );
  }
}