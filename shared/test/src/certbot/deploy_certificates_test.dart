/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  test('deploy certificates ...', () {
    prepareCloudflareCertHooks(
        hostname: 'auditor',
        domain: 'squarephone.biz',
        tld: 'biz',
        wildcard: false);

    Environment().hostname = 'auditor';
    Environment().domain = 'squarephone.biz';
    Environment().domainWildcard = false;
    Environment().autoAcquire = true;

    Certbot().deployCertificate();

    print('deploy has returned');
  });
}
