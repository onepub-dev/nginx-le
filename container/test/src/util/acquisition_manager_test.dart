@Timeout(Duration(minutes: 20))
import 'package:dcli/dcli.dart' hide equals;

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

    AcquisitionManager().enterAcquisitionMode(reload: false);
    expect(AcquisitionManager().inAcquisitionMode, equals(true));

    AcquisitionManager().leaveAcquistionMode(reload: false);
    expect(AcquisitionManager().inAcquisitionMode, equals(false));

    AcquisitionManager().enterAcquisitionMode(reload: false);
    expect(AcquisitionManager().inAcquisitionMode, equals(true));

    AcquisitionManager().leaveAcquistionMode(reload: false);
    expect(AcquisitionManager().inAcquisitionMode, equals(false));
  });

  test('Renew certificate', () {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: false,
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    Certbot().revokeAll();

    AcquisitionManager().acquistionCheck(reload: false);

    Certbot().renew(force: true);

//    'test/src/util/mock_deploy_hook'.run;
  }, skip: false);

  test('Revoke Invalid certificates', () {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: false,
        settingsFilename: 'cloudflare.yaml');
    Certbot().revokeAll();

    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        settingFilename: 'cloudflare.yaml',
        revoke: false);

    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        tld: 'org',
        wildcard: false,
        settingFilename: 'namecheap.yaml',
        revoke: false);

    expect(
        Certbot().deleteInvalidCertificates(
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
        settingFilename: 'cloudflare.yaml');
  });

  /// this should be run infrequently as we will hit the production certbot rate limiter.
  test('test switch from staging to production cloudflare ...', () async {
    Certbot().revokeAll();
    _acquire(
        hostname: 'robtest',
        domain: 'noojee.org',
        wildcard: false,
        tld: 'org',
        //emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml',
        production: false,
        revoke: false);

    var cert = Certificate.find(
        hostname: 'robtest',
        domain: 'noojee.org',
        wildcard: false,
        production: false)!;

    expect(cert, equals(isNotNull));
    expect(cert.hostname, equals('robtest'));
    expect(cert.domain, equals('noojee.org'));
    expect(cert.wildcard, equals(false));
    expect(cert.production, equals(false));

    Certbot().deleteInvalidCertificates(
        hostname: 'robtest',
        domain: 'noojee.org',
        wildcard: false,
        production: true);

    _acquire(
        hostname: 'robtest',
        domain: 'noojee.org',
        wildcard: false,
        tld: 'org',
        // emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml',
        production: true,
        revoke: false);

    cert = Certificate.find(
        hostname: 'robtest',
        domain: 'noojee.org',
        wildcard: false,
        production: true)!;

    expect(cert, equals(isNotNull));

    expect(cert.hostname, equals('robtest'));
    expect(cert.domain, equals('noojee.org'));
    expect(cert.wildcard, equals(false));
    expect(cert.production, equals(true));
  }, skip: false);

  test('acquire certificate cloudflare wildcard ...', () async {
    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: true,
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('acquire certificate cloudflare wildcard  *...', () async {
    _acquire(
        hostname: '*',
        domain: 'noojee.com.au',
        wildcard: true,
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('acquire certificate namecheap ...', () async {
    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        wildcard: false,
        tld: 'org',
        settingFilename: 'namecheap.yaml');
  });

  test('acquire certificate namecheap robtest5 ...', () async {
    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        wildcard: true,
        tld: 'org',
        settingFilename: 'namecheap.yaml');
  });

  test('acquire certificate namecheap wildcard  *...', () async {
    _acquire(
        hostname: '*',
        domain: 'noojee.org',
        wildcard: true,
        tld: 'org',
        settingFilename: 'namecheap.yaml');
  });

  /// The second attempt to acquire a certificate should do nothing.
  test('double acquire wildcard certificate ...', () async {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    AcquisitionManager().acquistionCheck(reload: false);

    expect(AcquisitionManager().inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
            hostname: 'auditor',
            domain: 'noojee.com.au',
            wildcard: true,
            production: false),
        equals(true));

    AcquisitionManager().acquistionCheck(reload: false);

    expect(AcquisitionManager().inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
            hostname: 'auditor',
            domain: 'noojee.com.au',
            wildcard: true,
            production: false),
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
    {required String hostname,
    required String domain,
    required String tld,
    bool wildcard = false,
    bool production = false,
    required String settingFilename,
    bool revoke = true}) {
  setup(
      hostname: hostname,
      domain: domain,
      wildcard: wildcard,
      tld: tld,
      production: production,
      settingsFilename: settingFilename);

  Certbot().clearBlockFlag();

  if (revoke) {
    Certbot().deleteInvalidCertificates(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        production: production);

    for (var certificate in Certbot().certificates()) {
      certificate!.revoke();
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));
  }

  AcquisitionManager().enterAcquisitionMode(reload: false);

  /// acquire the certificate
  AcquisitionManager().acquistionCheck(reload: false);

  expect(AcquisitionManager().inAcquisitionMode, equals(false));
  expect(Certbot().hasValidCertificate(), equals(true));
  expect(Certbot().isDeployed(), equals(true));
  expect(
      Certbot().wasIssuedFor(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          production: production),
      equals(true));

  if (revoke) {
    var cert = Certificate.find(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        production: production)!;

    expect(cert, equals(isNotNull));

    cert.revoke();
  }
}

void setup(
    {required String hostname,
    required String domain,
    required bool wildcard,
    required String settingsFilename,
    bool production = false,
    String? tld}) {
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
