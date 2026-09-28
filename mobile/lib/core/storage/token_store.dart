import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage chiffré des secrets de session.
/// Android → Keystore, iOS → Keychain (équivalent expo-secure-store).
class TokenStore {
  TokenStore();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kAccess = 'access';
  static const _kRefresh = 'refresh';
  static const _kUsername = 'cached_username';

  Future<String?> readAccess() => _storage.read(key: _kAccess);
  Future<String?> readRefresh() => _storage.read(key: _kRefresh);
  Future<String?> readUsername() => _storage.read(key: _kUsername);

  Future<void> saveSession({
    required String access,
    required String refresh,
    String? username,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
    if (username != null) await _storage.write(key: _kUsername, value: username);
  }

  Future<void> updateAccess(String access) =>
      _storage.write(key: _kAccess, value: access);

  Future<void> clearSession() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
