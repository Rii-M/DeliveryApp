class Customer {
  int? id;
  late String serverId;
  late String name;
  String? phone;
  String? address;
  String? email;
  String? pan;
  String? discountGroupId;
  String? areaId;
  String? customerGroupId;
  String? recordId;
  String? metaData;
  bool isActive = true;
  bool isAllowCredit = true;
  bool isSynced = true;
  String? pendingAction;

  Customer();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'name': name,
      'phone': phone,
      'address': address,
      'email': email,
      'pan': pan,
      'discount_group_id': discountGroupId,
      'area_id': areaId,
      'customer_group_id': customerGroupId,
      'record_id': recordId,
      'meta_data': metaData,
      'is_active': isActive ? 1 : 0,
      'is_allow_credit': isAllowCredit ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'pending_action': pendingAction,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    final customer = Customer();
    customer.id = map['id'] as int?;
    customer.serverId = map['server_id'] as String;
    customer.name = map['name'] as String;
    customer.phone = map['phone'] as String?;
    customer.address = map['address'] as String?;
    customer.email = map['email'] as String?;
    customer.pan = map['pan'] as String?;
    customer.discountGroupId = map['discount_group_id'] as String?;
    customer.areaId = map['area_id'] as String?;
    customer.customerGroupId = map['customer_group_id'] as String?;
    customer.recordId = map['record_id'] as String?;
    customer.metaData = map['meta_data'] as String?;
    customer.isActive = (map['is_active'] ?? 1) == 1;
    customer.isAllowCredit = (map['is_allow_credit'] ?? 1) == 1;
    customer.isSynced = (map['is_synced'] ?? 1) == 1;
    customer.pendingAction = map['pending_action'] as String?;
    return customer;
  }
}