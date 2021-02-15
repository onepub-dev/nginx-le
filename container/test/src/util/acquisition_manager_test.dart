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
    possibleCerts
        .add(PossibleCert('auditor', 'noojee.com.au', wildcard: false));
    possibleCerts.add(PossibleCert('*', 'noojee.com.au', wildcard: true));
    possibleCerts.add(PossibleCert('auditor', 'noojee.com.au', wildcard: true));
    possibleCerts.add(PossibleCert('robtest5', 'noojee.org', wildcard: true));
    possibleCerts.add(PossibleCert('*', 'noojee.org', wildcard: true));
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
  }, skip: true);

  test('Revoke certificate', () {
    env['DEBUG'] = 'true';
    Settings().setVerbose(enabled: true);
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    for (var certificate in Certificate.load()) {
      certificate.revoke();
    }
  }, skip: true);

  test('acquire certificate ...', () async {
    // Settings().setVerbose(enabled: true);
    // env['DEBUG'] = 'true';
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        wildcard: false,
        tld: 'com.au',
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

    if (Certbot().hasValidCertificate()) {
      Certbot().revoke(
          hostname: 'auditor',
          domain: 'noojee.com.au',
          wildcard: false,
          emailaddress: 'support@noojeeit.com.au',
          production: false);
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));

    /// tell the AcquisitionManager isolate that it needs to call the mock functions.
    // env['MOCK_ACQUISITION_MANAGER'] = 'true';

    AcquisitionManager.acquistionCheck(reload: false);

    expect(AcquisitionManager.inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
          hostname: 'auditor',
          domain: 'noojee.com.au',
          wildcard: false,
        ),
        equals(true));
  });

  test('acquire wildcard certificate ...', () async {
    setup(
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        wildcard: true,
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'cloudflare.yaml');

    Certbot().clearBlockFlag();

//    if (Certbot().hasValidCertificate()) {

    for (var certificate in Certificate.load()) {
      certificate.revoke();
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));

    /// tell the AcquisitionManager isolate that it needs to call the mock functions.
    // env['MOCK_ACQUISITION_MANAGER'] = 'true';

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

  test('acquire namecheap wildcard certificate ...', () async {
    setup(
        hostname: '*',
        domain: 'noojee.org',
        tld: 'org',
        wildcard: true,
        emailAddress: 'support@noojeeit.com.au',
        settingsFilename: 'namecheap.yaml');

    Certbot().clearBlockFlag();

//    if (Certbot().hasValidCertificate()) {

    for (var certificate in Certificate.load()) {
      certificate.revoke();
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));

    /// tell the AcquisitionManager isolate that it needs to call the mock functions.
    // env['MOCK_ACQUISITION_MANAGER'] = 'true';

    AcquisitionManager.acquistionCheck(reload: false);

    expect(AcquisitionManager.inAcquisitionMode, equals(false));
    expect(Certbot().hasValidCertificate(), equals(true));
    expect(Certbot().isDeployed(), equals(true));
    expect(
        Certbot().wasIssuedFor(
          hostname: '*',
          domain: 'noojee.org',
          wildcard: true,
        ),
        equals(true));
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
