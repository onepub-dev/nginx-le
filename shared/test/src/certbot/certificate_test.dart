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
}
