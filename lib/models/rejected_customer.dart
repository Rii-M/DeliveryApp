class RejectedCustomer {
  int? id;
  late String name;
  String? phone;
  String? reason;
  late DateTime createdDate;

  RejectedCustomer();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phone': phone,
      'reason': reason,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory RejectedCustomer.fromMap(Map<String, dynamic> map) {
    final entry = RejectedCustomer();
    entry.id = map['id'] as int?;
    entry.name = map['name'] as String;
    entry.phone = map['phone'] as String?;
    entry.reason = map['reason'] as String?;
    entry.createdDate = DateTime.parse(map['created_date'] as String);
    return entry;
  }
}
