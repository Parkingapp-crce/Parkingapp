// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'token_store.dart';

class _WebTokenStore implements TokenStore {
  const _WebTokenStore();

  @override
  Future<String?> read(String key) async => html.window.localStorage[key];

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    html.window.localStorage.remove(key);
  }
}

TokenStore createTokenStore() => const _WebTokenStore();
