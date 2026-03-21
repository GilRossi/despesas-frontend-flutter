import 'package:despesas_frontend/features/auth/domain/session_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore(this._storage);

  static const _refreshTokenKey = 'despesas.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clear() {
    return _storage.delete(key: _refreshTokenKey);
  }

  @override
  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> writeRefreshToken(String refreshToken) {
    return _storage.write(key: _refreshTokenKey, value: refreshToken);
  }
}
