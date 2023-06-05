@Timeout(Duration(minutes: 30))
library;

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

/// certificate renewals can take 20 minutes hence the long timeout above.

import 'package:nginx_le_shared/src/certbot/certbot_paths.dart';
import 'package:nginx_le_shared/src/certbot/certificate.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('certificate ...', () async {
    prepareEnvironment();
    final certificates = Certificate.load();

    for (final cert in certificates) {
      print(cert);
    }
  });

  test('check for certificate with matching details ...', () async {
    prepareEnvironment();

    print('loading certificates from: ${CertbotPaths().letsEncryptConfigPath}');
    final certificates = Certificate.load();

    print('Found ${certificates.length} certificates');

    for (final cert in certificates) {
      print(cert);
      // if (cert.wasIssuedFor())
    }
  });

  test('parse', () {
    const cert = '''
   Certificate Name: robtest5.squarephone.biz
     Domains: robtest5.squarephone.biz
     Expiry Date: 2021-05-13 04:36:22+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/robtest5.squarephone.biz/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/robtest5.squarephone.biz/privkey.pem
''';

    final certificate = Certificate.parse(cert.split('\n'));

    print(certificate);

    expect(
        certificate[0].wasIssuedFor(
            hostname: 'robtest5',
            domain: 'squarephone.biz',
            wildcard: false,
            production: false),
        equals(true));
  });
}
