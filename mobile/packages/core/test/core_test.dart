import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';

void main() {
  test('exposes auth endpoints', () {
    expect(ApiEndpoints.login, '/api/v1/auth/login/');
    expect(ApiEndpoints.profile, '/api/v1/auth/profile/');
  });
}
