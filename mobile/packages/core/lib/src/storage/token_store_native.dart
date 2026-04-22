import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_store.dart';

class _NativeTokenStore implements TokenStore {
  const _NativeTokenStore() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

TokenStore createTokenStore() => const _NativeTokenStore();
