import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'auth_final_token';
const _baseUrlKey = 'auth_base_url';
const _customerIdKey = 'auth_customer_id';
const _driverIdKey = 'auth_driver_id';
const _userIdKey = 'auth_user_id';
const _userNameKey = 'auth_user_name';
const _outletIdKey = 'auth_outlet_id';
const _emailKey = 'auth_email';
const _driverNameKey = 'auth_driver_name';

const _storage = FlutterSecureStorage();

Future<String?> getSavedToken() async {
  return _storage.read(key: _tokenKey);
}

Future<String?> getSavedBaseUrl() async {
  return _storage.read(key: _baseUrlKey);
}

Future<String?> getSavedCustomerId() async {
  return _storage.read(key: _customerIdKey);
}

Future<String?> getSavedDriverId() async {
  return _storage.read(key: _driverIdKey);
}

Future<String?> getSavedUserId() async {
  return _storage.read(key: _userIdKey);
}

Future<String?> getSavedDriverName() async {
  return _storage.read(key: _driverNameKey);
}

Future<String?> getSavedUserName() async {
  return _storage.read(key: _userNameKey);
}

Future<String?> getSavedOutletId() async {
  return _storage.read(key: _outletIdKey);
}

Future<String?> getEmail() async {
  return _storage.read(key: _emailKey);
}

Future<void> saveAuthData({
  required String token,
  required String baseUrl,
  String? userId,
  String? customerId,
  String? driverId,
  String? driverName,
  String? userName,
  String? email,
  String? outletId,
}) async {
  await _storage.write(key: _tokenKey, value: token);
  await _storage.write(key: _baseUrlKey, value: baseUrl);
  if (userId != null) {
    await _storage.write(key: _userIdKey, value: userId);
  }
  if (customerId != null) {
    await _storage.write(key: _customerIdKey, value: customerId);
  }
  if (driverId != null) {
    await _storage.write(key: _driverIdKey, value: driverId);
  }
  if (driverName != null) {
    await _storage.write(key: _driverNameKey, value: driverName);
  }
  if (userName != null) {
    await _storage.write(key: _userNameKey, value: userName);
  }
  if (email != null) {
    await _storage.write(key: _emailKey, value: email);
  }
  if (outletId != null) {
    await _storage.write(key: _outletIdKey, value: outletId);
  }
}

Future<void> clearAuthData() async {
  await _storage.delete(key: _tokenKey);
  await _storage.delete(key: _baseUrlKey);
  await _storage.delete(key: _customerIdKey);
  await _storage.delete(key: _driverIdKey);
  await _storage.delete(key: _userIdKey);
  await _storage.delete(key: _driverNameKey);
  await _storage.delete(key: _userNameKey);
  await _storage.delete(key: _outletIdKey);
}

Future<bool> hasSavedAuth() async {
  final token = await _storage.read(key: _tokenKey);
  return token != null && token.isNotEmpty;
}
