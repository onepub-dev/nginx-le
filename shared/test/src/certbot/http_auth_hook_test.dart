@Timeout(Duration(minutes: 60))
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('http_auth_hook', () {
    Settings().setVerbose(enabled: true);

    prepareEnvironment();

    var provider = HTTPAuthProvider();
    provider.authHook();
  });

  test('http_cleanup_hook', () {
    Settings().setVerbose(enabled: true);

    prepareEnvironment();

    var provider = HTTPAuthProvider();
    provider.cleanupHook();
  });
}
