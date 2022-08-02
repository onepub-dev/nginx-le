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
    prepareNameCheapCertHooks(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: false);

    Environment().hostname = 'auditor';
    Environment().domain = 'noojee.com.au';
    Environment().domainWildcard = false;
    Environment().autoAcquire = true;

    Certbot().deployCertificate();

    print('deploy has returned');
  });
}
