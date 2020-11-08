import 'package:nginx_le_shared/src/certbot/certificate.dart';
import 'package:test/test.dart';

import 'http_auth_hook_test.dart';

void main() {
  test('certificate ...', () async {
    prepareCertHooks();
    var certificates = Certificate.load();

    for (var cert in certificates) {
      print(cert.toString());
    }
  });
}
