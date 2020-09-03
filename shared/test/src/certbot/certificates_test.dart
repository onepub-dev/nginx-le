import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  group('Certificates', () {
    test('With Staging Certificate', () {
      var lines =
          ''' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.noojee.org
     Domains: slayer.noojee.org
     Expiry Date: 2020-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.noojee.org/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.noojee.org/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
              .split('\n');

      var certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      var certificate = certificates[0];
      expect(certificate.fqdn, equals('slayer.noojee.org'));
      expect(certificate.domains, equals('slayer.noojee.org'));
      expect(
          certificate.certificatePath,
          equals(
              '/etc/letsencrypt/config/live/slayer.noojee.org/fullchain.pem'));
      expect(certificate.privateKeyPath,
          equals('/etc/letsencrypt/config/live/slayer.noojee.org/privkey.pem'));
      expect(certificate.production, equals(true));
      expect(certificate.expiryDate,
          equals(DateTime.parse('2020-10-27 06:10:05+00:00')));
    });

    test('No Certificates', () {
      var lines =
          ''' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 No certs found.
 - - - - - - - - - - - - - -'''
              .split('\n');

      var certificates = Certificate.parse(lines);
      expect(certificates.length, equals(0));
    });

    test('Has expired', () {
      var lines =
          ''' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.noojee.org
     Domains: slayer.noojee.org
     Expiry Date: 1920-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.noojee.org/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.noojee.org/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
              .split('\n');

      var certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      var certificate = certificates[0];
      expect(certificate.hasExpired(), equals(true));
    });

    test('Has Not expired', () {
      var lines =
          ''' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.noojee.org
     Domains: slayer.noojee.org
     Expiry Date: 2030-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.noojee.org/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.noojee.org/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
              .split('\n');

      var certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      var certificate = certificates[0];
      expect(certificate.hasExpired(), equals(false));
    });

    test('Print Certificate', () {
      var lines =
          ''' - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 Found the following certs:'
   Certificate Name: slayer.noojee.org
     Domains: slayer.noojee.org
     Expiry Date: 2030-10-27 06:10:05+00:00 (INVALID: TEST_CERT)
     Certificate Path: /etc/letsencrypt/config/live/slayer.noojee.org/fullchain.pem
     Private Key Path: /etc/letsencrypt/config/live/slayer.noojee.org/privkey.pem
 - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -'''
              .split('\n');

      var certificates = Certificate.parse(lines);
      expect(certificates.length, equals(1));
      var certificate = certificates[0];

      print(certificate);
    });
  });
}
