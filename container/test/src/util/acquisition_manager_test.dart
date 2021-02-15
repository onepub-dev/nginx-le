@Timeout(Duration(minutes: 20))
import 'package:dcli/dcli.dart' hide equals;
import 'package:meta/meta.dart';

import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import 'mock_cerbot_paths.dart';

var possibleCerts = <PossibleCert>[];
void main() {
  setUpAll(() {
    possibleCerts.add(PossibleCert('*', 'noojee.com.au', wildcard: true));
    possibleCerts
        .add(PossibleCert('auditor', 'noojee.com.au', wildcard: false));
    possibleCerts.add(PossibleCert('auditor', 'noojee.com.au', wildcard: true));

    possibleCerts.add(PossibleCert('*', 'noojee.org', wildcard: true));
    possibleCerts.add(PossibleCert('robtest5', 'noojee.org', wildcard: false));
    possibleCerts.add(PossibleCert('robtest5', 'noojee.org', wildcard: true));
    possibleCerts.add(PossibleCert('robtest', 'noojee.org', wildcard: false));
    possibleCerts.add(PossibleCert('auditor', 'noojee.org', wildcard: false));
  });
  test('acquisition manager ...', () async {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: false,
        settingsFilename: 'cloudflare.yaml');

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(false));

    AcquisitionManager.enterAcquisitionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(true));

    AcquisitionManager.leaveAcquistionMode();
    expect(AcquisitionManager.inAcquisitionMode, equals(false));
  });

  test('Renew certificate', () {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: false,
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    AcquisitionManager.acquistionCheck(reload: false);

    Certbot().renew(force: true);

//    'test/src/util/mock_deploy_hook'.run;
  }, skip: false);

  test('Revoke Invalid certificates', () {
    Certbot().revokeAll();

    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'cloudflare.yaml',
        revoke: false);

    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        tld: 'org',
        wildcard: false,
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml',
        revoke: false);

    expect(
        Certbot().revokeInvalidCertificates(
            hostname: 'auditor',
            domain: 'noojee.com.au',
            wildcard: false,
            production: false),
        equals(2));
  });
  test('Revoke All certificate', () {
    Certbot().revokeAll();
    expect(Certificate.load().length, equals(0));

    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: false,
        tld: 'com.au',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'cloudflare.yaml',
        revoke: false);

    expect(Certificate.load().length, equals(1));

    Certbot().revokeAll();

    expect(Certificate.load().length, equals(0));
  }, skip: false);

  test('acquire certificate cloudflare ...', () async {
    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: false,
        tld: 'com.au',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('acquire certificate cloudflare wildcard ...', () async {
    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: true,
        tld: 'com.au',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('acquire certificate cloudflare wildcard  *...', () async {
    _acquire(
        hostname: '*',
        domain: 'noojee.com.au',
        wildcard: true,
        tld: 'com.au',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('acquire certificate namecheap ...', () async {
    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        wildcard: false,
        tld: 'org',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml');
  });

  test('acquire certificate namecheap wildcard ...', () async {
    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        wildcard: true,
        tld: 'org',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml');
  });

  test('acquire certificate namecheap wildcard  *...', () async {
    _acquire(
        hostname: '*',
        domain: 'noojee.org',
        wildcard: true,
        tld: 'org',
        emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml');
  });

  /// The second attempt to acquire a certificate should do nothing.
  test('double acquire wildcard certificate ...', () async {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    AcquisitionManager.acquistionCheck(reload: false);

    expect(AcquisitionManager.inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
          hostname: 'auditor',
          domain: 'noojee.com.au',
          wildcard: true,
        ),
        equals(true));

    AcquisitionManager.acquistionCheck(reload: false);

    expect(AcquisitionManager.inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
          hostname: 'auditor',
          domain: 'noojee.com.au',
          wildcard: true,
        ),
        equals(true));
  });

//   test('isdeployed...', () {
//     setup(
//         hostname: 'auditor',
//         domain: 'noojee.com.au',
//         tld: 'com.au',
//         wildcard: false,
//         emailAddress: 'support@noojeeit.com.au',
//         settingsFilename: 'cloudflare.yaml');

//     var certificate =
//         join(CertbotPaths().nginxCertPath, CertbotPaths().FULLCHAIN_FILE);
//     var privatekey =
//         join(CertbotPaths().nginxCertPath, CertbotPaths().PRIVATE_KEY_FILE);

//     if (!exists(dirname(certificate))) {
//       createDir(dirname(certificate), recursive: true);
//     }
//     if (!exists(dirname(privatekey))) {
//       createDir(dirname(privatekey), recursive: true);
//     }

//     if (exists(certificate)) {
//       delete(certificate);
//     }

//     expect(Certbot().isDeployed(), equals(false));

//     if (exists(privatekey)) {
//       delete(privatekey);
//     }

//     expect(Certbot().isDeployed(), equals(false));

//     touch(privatekey, create: true);

//     expect(Certbot().isDeployed(), equals(false));

//     touch(certificate, create: true);

//     expect(Certbot().isDeployed(), equals(true));

//     delete(certificate);
//     delete(privatekey);
//   });
}

void _acquire(
    {String hostname,
    String domain,
    String tld,
    bool wildcard,
    String emailAddress,
    bool production = false,
    String settingFilename,
    bool revoke = true}) {
  setup(
      hostname: hostname,
      domain: domain,
      wildcard: wildcard,
      tld: tld,
      emailAddress: emailAddress,
      settingsFilename: settingFilename);

  Certbot().clearBlockFlag();

  if (revoke) {
    Certbot().revokeInvalidCertificates(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        production: production);

    for (var certificate in Certbot().certificates()) {
      certificate.revoke();
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));
  }

  AcquisitionManager.enterAcquisitionMode();

  /// acquire the certificate
  AcquisitionManager.acquistionCheck(reload: false);

  expect(AcquisitionManager.inAcquisitionMode, equals(false));
  expect(Certbot().hasValidCertificate(), equals(true));
  expect(Certbot().isDeployed(), equals(true));
  expect(
      Certbot().wasIssuedFor(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
      ),
      equals(true));

  if (revoke) {
    Certbot().revoke(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        emailaddress: 'support@noojeeit.com.au',
        production: production);
  }
}

void setup(
    {@required String hostname,
    @required String domain,
    @required bool wildcard,
    @required String settingsFilename,
    bool production = false,
    String emailAddress,
    String tld}) {
  var paths = MockCertbotPaths(
      hostname: hostname,
      domain: domain,
      wildcard: wildcard,
      production: production,
      tld: tld,
      settingsFilename: settingsFilename,
      possibleCerts: possibleCerts);

  paths.wire();

  config_mock_deploy_hook();
}

void config_mock_deploy_hook() {
  var path = 'test/src/util/mock_deploy_hook';
  if (!exists(path)) {
    var script = Script.fromFile('$path.dart');
    script.compile();
  }

  Environment().certbotDeployHookPath = path;
}
