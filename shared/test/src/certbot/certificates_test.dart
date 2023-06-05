@Timeout(Duration(minutes: 60))
library;

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

void main() {
  group('Certificates', () {
    test('With Staging Certificate', () {
      final lines = '''
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.squarephone.biz
     Domains: slayer.squarephone.biz
     Expiry Date: 2020-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
          .split('\n');

      final certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      final certificate = certificates[0];
      expect(certificate.fqdn, equals('slayer.squarephone.biz'));
      expect(certificate.domains, equals('slayer.squarephone.biz'));
      expect(
          certificate.certificatePath,
          equals(join(CertbotPaths().letsEncryptLivePath,
              'slayer.squarephone.biz/fullchain.pem')));
      expect(
          certificate.privateKeyPath,
          equals(join(CertbotPaths().letsEncryptLivePath,
              'slayer.squarephone.biz/privkey.pem')));
      expect(certificate.production, equals(false));
      expect(certificate.expiryDate,
          equals(DateTime.parse('2020-10-27 06:10:05+00:00')));
    });

    test('No Certificates', () {
      final lines = '''
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 No certs found.
 - - - - - - - - - - - - - -'''
          .split('\n');

      final certificates = Certificate.parse(lines);
      expect(certificates.length, equals(0));
    });

    test('Has expired', () {
      final lines = '''
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.squarephone.biz
     Domains: slayer.squarephone.biz
     Expiry Date: 1920-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
          .split('\n');

      final certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      final certificate = certificates[0];
      expect(certificate.hasExpired(), equals(true));
    });

    test('Has Not expired', () {
      final lines = '''
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.squarephone.biz
     Domains: slayer.squarephone.biz
     Expiry Date: 2030-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
          .split('\n');

      final certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      final certificate = certificates[0];
      expect(certificate.hasExpired(), equals(false));
    });

    test('Print Certificate', () {
      final lines = '''
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.squarephone.biz
     Domains: slayer.squarephone.biz
     Expiry Date: 2030-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.squarephone.biz/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
          .split('\n');

      final certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      final certificate = certificates[0];

      print(certificate);
    });
  });
}
