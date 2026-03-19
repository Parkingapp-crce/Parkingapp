import '../storage/secure_storage_service.dart';

class TokenManager {
  final SecureStorageService _storage;

  TokenManager(this._storage);

  Future<String?> getAccessToken() => _storage.getAccessToken();
  Future<String?> getRefreshToken() => _storage.getRefreshToken();

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) =>
      _storage.saveTokens(access: access, refresh: refresh);

  Future<void> clearTokens() => _storage.clearTokens();
  Future<bool> hasTokens() => _storage.hasTokens();
}
