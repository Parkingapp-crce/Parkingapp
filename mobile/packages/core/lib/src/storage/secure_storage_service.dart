import 'token_store.dart';
import 'token_store_native.dart'
    if (dart.library.html) 'token_store_web.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final TokenStore _store;

  SecureStorageService({TokenStore? store})
      : _store = store ?? createTokenStore();

  Future<String?> getAccessToken() => _safeRead(_accessTokenKey);
  Future<String?> getRefreshToken() => _safeRead(_refreshTokenKey);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _store.write(_accessTokenKey, access),
      _store.write(_refreshTokenKey, refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _safeDelete(_accessTokenKey),
      _safeDelete(_refreshTokenKey),
    ]);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> _safeRead(String key) async {
    try {
      return await _store.read(key);
    } catch (_) {
      await clearTokens();
      return null;
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _store.delete(key);
    } catch (_) {
      // Treat delete failures as an already-cleared session.
    }
  }
}
