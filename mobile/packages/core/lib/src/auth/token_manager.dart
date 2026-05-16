import '../storage/secure_storage_service.dart';

class TokenManager {
  final SecureStorageService _storage;

  TokenManager(this._storage);

  Future<String?> getAccessToken() => _storage.getAccessToken();
  Future<String?> getRefreshToken() => _storage.getRefreshToken();
  Future<String?> getEmail() => _storage.getEmail();
  Future<String?> getPassword() => _storage.getPassword();

  Future<void> saveTokens({required String access, required String refresh}) =>
      _storage.saveTokens(access: access, refresh: refresh);

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) => _storage.saveCredentials(email: email, password: password);

  Future<void> clearTokens() => _storage.clearTokens();
  Future<void> clearCredentials() => _storage.clearCredentials();
  Future<bool> hasTokens() => _storage.hasTokens();
}
