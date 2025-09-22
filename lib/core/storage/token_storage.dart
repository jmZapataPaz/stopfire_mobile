import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> clearToken();
}

class SecureTokenStorage implements TokenStorage {
  static const _key = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) => _storage.write(key: _key, value: token);

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> clearToken() => _storage.delete(key: _key);
}