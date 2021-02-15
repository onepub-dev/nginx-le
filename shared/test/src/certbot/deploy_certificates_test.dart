import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  test('deploy certificates ...', () {
    prepareCertHooks();

    Environment().hostname = 'auditor';
    Environment().domain = 'noojee.com.au';
    Environment().domainWildcard = false;
    Environment().autoAcquire = true;

    Certbot().deployCertificates();

    print('deploy has returned');
  });
}
