import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('http_auth_hook', () {
    prepareEnvironment();

    HTTPAuthProvider().authHook();
  });

  test('http_cleanup_hook', () {
    prepareEnvironment();

    HTTPAuthProvider().cleanupHook();
  });
}
