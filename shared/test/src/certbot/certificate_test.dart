import 'package:nginx_le_shared/src/certbot/certbot_paths.dart';
import 'package:nginx_le_shared/src/certbot/certificate.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('certificate ...', () async {
    prepareEnvironment();
    var certificates = Certificate.load();

    for (var cert in certificates) {
      print(cert.toString());
    }
  });

  test('check for certificate with matching details ...', () async {
    prepareEnvironment();

    print('loading certificates from: ${CertbotPaths().letsEncryptConfigPath}');
    var certificates = Certificate.load();

    print('Found ${certificates.length} certificates');

    for (var cert in certificates) {
      print(cert.toString());
      // if (cert.wasIssuedFor())

    }
  });
}
