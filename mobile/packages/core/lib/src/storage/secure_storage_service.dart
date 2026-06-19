import 'token_store.dart';
import 'token_store_native.dart' if (dart.library.html) 'token_store_web.dart';

class SecureStorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'saved_email';
  static const _passwordKey = 'saved_password';
  static const _guardEmailKey = 'saved_guard_email';
  static const _guardPasswordKey = 'saved_guard_password';

  final TokenStore _store;

  SecureStorageService({TokenStore? store})
    : _store = store ?? createTokenStore();

  Future<String?> getAccessToken() => _safeRead(_accessTokenKey);
  Future<String?> getRefreshToken() => _safeRead(_refreshTokenKey);
  Future<String?> getEmail() => _safeRead(_emailKey);
  Future<String?> getPassword() => _safeRead(_passwordKey);
  Future<String?> getGuardEmail() => _safeRead(_guardEmailKey);
  Future<String?> getGuardPassword() => _safeRead(_guardPasswordKey);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _safeWrite(_accessTokenKey, access),
      _safeWrite(_refreshTokenKey, refresh),
    ]);
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _safeWrite(_emailKey, email),
      _safeWrite(_passwordKey, password),
    ]);
  }

  Future<void> saveGuardCredentials({
    required String email,
    required String password,
  }) async {
    await Future.wait([
      _safeWrite(_guardEmailKey, email),
      _safeWrite(_guardPasswordKey, password),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _safeDelete(_accessTokenKey),
      _safeDelete(_refreshTokenKey),
    ]);
  }

  Future<void> clearCredentials() async {
    await Future.wait([_safeDelete(_emailKey), _safeDelete(_passwordKey)]);
  }

  Future<void> clearGuardCredentials() async {
    await Future.wait([
      _safeDelete(_guardEmailKey),
      _safeDelete(_guardPasswordKey),
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

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _store.write(key, value);
    } catch (_) {
      await clearTokens();
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
