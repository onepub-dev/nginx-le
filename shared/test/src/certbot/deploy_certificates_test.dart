import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  test('deploy certificates ...', () {
    prepareCertHooks();

    /// certbotRootPath

    Certbot().deployCertificates(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        reload:
            false, // don't try to reload nginx as it won't be running as yet.
        wildcard: false,
        autoAcquireMode: true);

    print('deploy has returned');
  });
}
