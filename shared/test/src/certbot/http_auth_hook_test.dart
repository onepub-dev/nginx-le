import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import '../util/with_test_environment.dart';

void main() {
  test('http_auth_hook', () async {
    await withTestEnvironment(() {
      HTTPAuthProvider().authHook();
    });
  });

  test('http_cleanup_hook', () async {
    await withTestEnvironment(() {
      HTTPAuthProvider().cleanupHook();
    });
  });
}
