@Timeout(Duration(minutes: 20))
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart' hide equals;

import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';
import 'package:test/test.dart';

import 'mock_cerbot_paths.dart';

List<PossibleCert> possibleCerts = <PossibleCert>[];
void main() {
  setUpAll(() {
    possibleCerts
      ..add(PossibleCert('*', 'noojee.com.au', wildcard: true))
      ..add(PossibleCert('auditor', 'noojee.com.au', wildcard: false))
      ..add(PossibleCert('auditor', 'noojee.com.au', wildcard: true))
      ..add(PossibleCert('*', 'noojee.org', wildcard: true))
      ..add(PossibleCert('robtest5', 'noojee.org', wildcard: false))
      ..add(PossibleCert('robtest5', 'noojee.org', wildcard: true))
      ..add(PossibleCert('robtest', 'noojee.org', wildcard: false))
      ..add(PossibleCert('auditor', 'noojee.org', wildcard: false))
      ..add(PossibleCert('', 'onepub.dev', wildcard: false));

    Environment().certbotDNSWaitTime = 10;
  });
  test('acquisition manager ...', () async {
    runInTestScope(() {
      AcquisitionManager().enterAcquisitionMode(reload: false);
      expect(AcquisitionManager().inAcquisitionMode, equals(true));

      AcquisitionManager().leaveAcquistionMode(reload: false);
      expect(AcquisitionManager().inAcquisitionMode, equals(false));

      AcquisitionManager().enterAcquisitionMode(reload: false);
      expect(AcquisitionManager().inAcquisitionMode, equals(true));

      AcquisitionManager().leaveAcquistionMode(reload: false);
      expect(AcquisitionManager().inAcquisitionMode, equals(false));
    },
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('Renew certificate', () {
    runInTestScope(() {
      Certbot().clearBlockFlag();
      Certbot().revokeAll();
      AcquisitionManager().acquireIfRequired(reload: false);
      Certbot().renew(force: true);
    },
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  },
      skip: false,
      tags: ['slow'],
      timeout: const Timeout(Duration(minutes: 15)));

  test('Revoke Invalid certificates', () {
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

  test('Acquire robtest5.noojee.org via namecheap', () {
    _acquire(
        hostname: 'robtest5',
        domain: 'noojee.org',
        tld: 'org',
        settingFilename: 'namecheap.yaml',
        revoke: false);
  });

  test('Revoke All certificate', () {
    Certbot().revokeAll();
    expect(Certificate.load().length, equals(0));

    _acquire(
        hostname: 'auditor',
        domain: 'noojee.com.au',
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
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  });

  test('Acquire onepub.dev via cloudflare', () {
    _acquire(
        hostname: '',
        domain: 'noojee.com.au',
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
  });

  /// this should be run infrequently as we will hit the production certbot
  /// rate limiter.
  test('test switch from staging to production cloudflare ...', () async {
    Certbot().revokeAll();
    _acquire(
        hostname: 'robtest',
        domain: 'noojee.org',
        tld: 'org',
        //emailAddress: 'support@noojeeit.com.au',
        settingFilename: 'namecheap.yaml',
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
    runInTestScope(() {
      Certbot().clearBlockFlag();

      AcquisitionManager().acquireIfRequired(reload: false);

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

      AcquisitionManager().acquireIfRequired(reload: false);

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
    },
        hostname: 'auditor',
        domain: 'noojee.com.au',
        tld: 'com.au',
        settingFilename: 'cloudflare.yaml');
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
  });
}

void _acquire(
    {required String hostname,
    required String domain,
    required String tld,
    required String settingFilename,
    bool wildcard = false,
    bool production = false,
    bool revoke = true}) {
  final settingsPath = truepath('test', 'config', settingFilename);
  final settings = SettingsYaml.load(pathToSettings: settingsPath);

  configMockDeployHook();

  withTempDir((dir) {
    withEnvironment(() {
      CertbotPaths.withTestScope(
          dir,
          () => _runAcquire(
              hostname: hostname,
              domain: domain,
              tld: tld,
              wildcard: wildcard,
              production: production,
              revoke: revoke));
    }, environment: {
      Environment.hostnameKey: hostname,
      Environment.domainKey: domain,
      Environment.domainWildcardKey: '$wildcard',
      Environment().productionKey: '$production',
      Environment.smtpServerKey: 'localhost',
      Environment.smtpServerPortKey: '1025',
      Environment.emailaddressKey: 'test@noojee.com.au',
      Environment.authProviderKey: settings['AUTH_PROVIDER'] as String,
      Environment.authProviderTokenKey:
          settings[Environment.authProviderTokenKey] as String,
      Environment.authProviderUsernameKey:
          settings[Environment.authProviderUsernameKey] as String,
      Environment.authProviderEmailAddressKey:
          settings[Environment.authProviderEmailAddressKey] as String
    });
  });
}

void runInTestScope(void Function() test,
    {required String hostname,
    required String domain,
    required String tld,
    required String settingFilename,
    bool wildcard = false,
    bool production = false,
    bool revoke = true}) {
  final settingsPath = truepath('test', 'config', settingFilename);
  final settings = SettingsYaml.load(pathToSettings: settingsPath);

  configMockDeployHook();

  withTempDir((dir) {
    withEnvironment(() {
      CertbotPaths.withTestScope(
          dir,
          () => _runAcquire(
              hostname: hostname,
              domain: domain,
              tld: tld,
              wildcard: wildcard,
              production: production,
              revoke: revoke));
    }, environment: {
      Environment.hostnameKey: hostname,
      Environment.domainKey: domain,
      Environment.domainWildcardKey: '$wildcard',
      Environment().productionKey: '$production',
      Environment.smtpServerKey: 'localhost',
      Environment.smtpServerPortKey: '1025',
      Environment.emailaddressKey: 'test@noojee.com.au',
      Environment.authProviderKey: settings['AUTH_PROVIDER'] as String,
      Environment.authProviderTokenKey:
          settings[Environment.authProviderTokenKey] as String,
      Environment.authProviderUsernameKey:
          settings[Environment.authProviderUsernameKey] as String,
      Environment.authProviderEmailAddressKey:
          settings[Environment.authProviderEmailAddressKey] as String
    });
  });
}

void _runAcquire(
    {required String hostname,
    required String domain,
    required String tld,
    bool wildcard = false,
    bool production = false,
    bool revoke = true}) {
  Certbot().clearBlockFlag();

  if (revoke) {
    Certbot().deleteInvalidCertificates(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        production: production);

    for (final certificate in Certbot().certificates()) {
      certificate!.revoke();
    }
    expect(Certbot().hasValidCertificate(), equals(false));
    expect(Certbot().isDeployed(), equals(false));
  }

  AcquisitionManager().enterAcquisitionMode(reload: false);

  /// acquire the certificate
  AcquisitionManager().acquireIfRequired(reload: false);

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
    final cert = Certificate.find(
        hostname: hostname,
        domain: domain,
        wildcard: wildcard,
        production: production)!;

    expect(cert, equals(isNotNull));

    cert.revoke();
  }
}

void configMockDeployHook() {
  const path = 'test/src/util/mock_deploy_hook';
  if (!exists(path)) {
    DartScript.fromFile('$path.dart').compile();
  }

  Environment().certbotDeployHookPath = path;
}
