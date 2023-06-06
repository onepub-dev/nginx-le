@Timeout(Duration(minutes: 20))
library;
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:dcli_core/dcli_core.dart' as core;
import 'package:nginx_le_container/src/util/acquisition_manager.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';
import 'package:test/test.dart';

import 'mock_cerbot_paths.dart';

List<PossibleCert> possibleCerts = <PossibleCert>[];
void main() {
  setUpAll(() {
    Settings().setVerbose(enabled: true);
    possibleCerts
      ..add(PossibleCert('*', 'test.squarephone.biz', wildcard: true))
      ..add(PossibleCert('auditor', 'test.squarephone.biz', wildcard: false))
      ..add(PossibleCert('auditor', 'test.squarephone.biz', wildcard: true))
      ..add(PossibleCert('*', 'squarephone.biz', wildcard: true))
      ..add(PossibleCert('robtest5', 'squarephone.biz', wildcard: false))
      ..add(PossibleCert('robtest5', 'squarephone.biz', wildcard: true))
      ..add(PossibleCert('robtest', 'squarephone.biz', wildcard: false))
      ..add(PossibleCert('auditor', 'squarephone.biz', wildcard: false))
      ..add(PossibleCert('', 'test.squarephone.biz', wildcard: false));

    Environment().certbotDNSWaitTime = 60;
  });

  test('acquisition manager ...', () async {
    await runInTestScope(() async {
      await forCertificate(
        hostname: 'auditor',
        domain: 'test.squarephone.biz',
        () async {
          AcquisitionManager().enterAcquisitionMode(reload: false);
          expect(AcquisitionManager().inAcquisitionMode, equals(true));

          AcquisitionManager().leaveAcquistionMode(reload: false);
          expect(AcquisitionManager().inAcquisitionMode, equals(false));

          AcquisitionManager().enterAcquisitionMode(reload: false);
          expect(AcquisitionManager().inAcquisitionMode, equals(true));

          AcquisitionManager().leaveAcquistionMode(reload: false);
          expect(AcquisitionManager().inAcquisitionMode, equals(false));
        },
      );
    }, settingFilename: 'cloudflare.yaml');
  });

  test('Renew certificate', () async {
    await runInTestScope(
      settingFilename: 'cloudflare.yaml',
      () async {
        await forCertificate(
          hostname: 'auditor',
          domain: 'test.squarephone.biz',
          () async {
            Certbot().clearBlockFlag();
            Certbot().revokeAll();
            await simpleAcquire();
            Certbot().renew(force: true);
          },
        );
      },
    );
  },
      skip: false,
      tags: ['slow'],
      timeout: const Timeout(Duration(minutes: 15)));

  test('Revoke Invalid certificates', () async {
    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(
          hostname: 'auditor',
          domain: 'test.squarephone.biz',
          wildcard: true, () async {
        Certbot().revokeAll();

        await simpleAcquire();

        await forCertificate(hostname: 'robtest5', domain: 'squarephone.biz',
            () async {
          await simpleAcquire();
          expect(
              Certbot().deleteInvalidCertificates(
                  hostname: 'auditor',
                  domain: 'test.squarephone.biz',
                  wildcard: false,
                  production: false),
              equals(2));
        });
      });
    });
  });

  test('Acquire robtest5.squarephone.biz via cloudflare', () async {
    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(hostname: 'robtest5', domain: 'squarephone.biz',
          () async {
        await simpleAcquire();
      });
    });
  });

  test('Revoke All certificate', () async {
    Certbot().revokeAll();
    expect(Certificate.load().length, equals(0));

    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(hostname: 'auditor', domain: 'test.squarephone.biz',
          () async {
        await simpleAcquire();

        expect(Certificate.load().length, equals(1));

        Certbot().revokeAll();

        expect(Certificate.load().length, equals(0));
      });
    });
  }, skip: false);

  test('Acquire squarephone.biz via cloudflare', () async {
    Certbot().revokeAll();
    expect(Certificate.load().length, equals(0));

    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(hostname: '', domain: 'squarephone.biz', () async {
        await simpleAcquire();

        expect(Certificate.load().length, equals(1));
      });
    });
  });

  /// this should be run infrequently as we will hit the production certbot
  /// rate limiter.
  test('test switch from staging to production cloudflare ...', () async {
    Certbot().revokeAll();

    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(hostname: 'robtest', domain: 'squarephone.biz',
          () async {
        await simpleAcquire();
        expect(Certificate.load().length, equals(1));

        var cert = Certificate.find(
            hostname: 'robtest',
            domain: 'squarephone.biz',
            wildcard: false,
            production: false)!;

        expect(cert, equals(isNotNull));
        expect(cert.hostname, equals('robtest'));
        expect(cert.domain, equals('squarephone.biz'));
        expect(cert.wildcard, equals(false));
        expect(cert.production, equals(false));

        Certbot().deleteInvalidCertificates(
            hostname: 'robtest',
            domain: 'squarephone.biz',
            wildcard: false,
            production: true);

        await forCertificate(
            hostname: 'robtest',
            domain: 'squarephone.biz',
            production: true, () async {
          await simpleAcquire();
          cert = Certificate.find(
              hostname: 'robtest',
              domain: 'squarephone.biz',
              wildcard: false,
              production: true)!;

          expect(cert, equals(isNotNull));

          expect(cert.hostname, equals('robtest'));
          expect(cert.domain, equals('squarephone.biz'));
          expect(cert.wildcard, equals(false));
          expect(cert.production, equals(true));
        });
      });
    });
  }, skip: false);

  test('acquire certificate cloudflare wildcard ...', () async {
    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(
          hostname: 'auditor',
          domain: 'squarephone.biz',
          wildcard: true, () async {
        await simpleAcquire();
      });
    });
  });

  test('acquire certificate cloudflare wildcard  *.squarephone.biz', () async {
    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(
          hostname: '*', domain: 'squarephone.biz', wildcard: true, () async {
        await simpleAcquire();
      });
    });
  });

  test('acquire certificate namecheap squarephone.biz', () async {
    await runInTestScope(settingFilename: 'namecheap.yaml', () async {
      await forCertificate(
          hostname: '', domain: 'squarephone.biz', wildcard: true, () async {
        await simpleAcquire();
      });
    });
  }, skip: true);

  test('acquire certificate namecheap robtest5.squarephone.biz', () async {
    await runInTestScope(settingFilename: 'namecheap.yaml', () async {
      await forCertificate(
          hostname: 'robtest5',
          domain: 'squarephone.biz',
          wildcard: true, () async {
        await simpleAcquire();
      });
    });
  }, skip: true);

  test('acquire certificate namecheap wildcard  *.squarephone.biz', () async {
    await runInTestScope(settingFilename: 'namecheap.yaml', () async {
      await forCertificate(
          hostname: '*', domain: 'squarephone.biz', wildcard: true, () async {
        await simpleAcquire();
      });
    });
  }, skip: true);

  /// The second attempt to acquire a certificate should do nothing.
  test('double acquire wildcard certificate ...', () async {
    await runInTestScope(settingFilename: 'cloudflare.yaml', () async {
      await forCertificate(
        hostname: 'auditor',
        domain: 'squarephone.biz',
        wildcard: true,
        () async {
          Certbot().clearBlockFlag();
          Certbot().revokeAll();

          await AcquisitionManager().acquireIfRequired(reload: false);

          expect(AcquisitionManager().inAcquisitionMode, equals(false));
          expect(Certbot().hasValidCertificate(), equals(true));
          expect(Certbot().isDeployed(), equals(true));
          expect(
              Certbot().wasIssuedFor(
                  hostname: 'auditor',
                  domain: 'squarephone.biz',
                  wildcard: true,
                  production: false),
              equals(true));

          await AcquisitionManager().acquireIfRequired(reload: false);

          expect(AcquisitionManager().inAcquisitionMode, equals(false));
          expect(Certbot().hasValidCertificate(), equals(true));
          expect(Certbot().isDeployed(), equals(true));
          expect(
              Certbot().wasIssuedFor(
                  hostname: 'auditor',
                  domain: 'squarephone.biz',
                  wildcard: true,
                  production: false),
              equals(true));
        },
      );
    });
  });
}

// Future<void> _acquire(
//   Future<void> Function() test,
//     {required hostname,
//     required domain,
//     required settingFilename,
//     wildcard = false,
//     production = false,

// ) async {
//        await runInTestScope(
//       settingFilename: settingsFilename,
//       () async {
//         await forCertificate(

//      hostname: hostname,
//         domain: domain,
//         wildcard: wildcard,
//         production: production,

//          () async {
//         await simpleAcquire();

//           await test();
// });
//       });
// }

Future<void> simpleAcquire() async {
  AcquisitionManager().enterAcquisitionMode(reload: false);
  await AcquisitionManager().acquireIfRequired(reload: false);
  AcquisitionManager().leaveAcquistionMode(reload: false);
}
// Future<void> _acquire(
//     {required hostname,
//     required domain,
//     required settingFilename,
//     wildcard = false,
//     production = false,
//     revoke = true}) async {
//   await runInTestScope(() async {
//     await forCertificate(
//         hostname: hostname,
//         domain: domain,
//         wildcard: wildcard,
//         production: production, () async {
//       await _runAcquire(
//           hostname: hostname,
//           domain: domain,
//           wildcard: wildcard,
//           production: production,
//           revoke: revoke);
//     });
//   });
// }

Future<void> runInTestScope(
  void Function() test, {
  required String settingFilename,
}) async {
  final settingsPath = truepath('test', 'config', settingFilename);
  final settings = SettingsYaml.load(pathToSettings: settingsPath);

  configMockDeployHook();

  await core.withTempDir((dir) async {
    await withEnvironment(() async {
      await CertbotPaths.withTestScope(dir, () async => test());
    }, environment: {
      Environment.smtpServerKey: 'localhost',
      Environment.smtpServerPortKey: '1025',
      Environment.emailaddressKey: 'test@squarephone.biz',
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

/// Sets the domain related environment variable that
/// control the details of the certificate being managed.
Future<void> forCertificate(
  Future<void> Function() test, {
  required String hostname,
  required String domain,
  bool wildcard = false,
  bool production = false,
}) async {
  await withEnvironment(() async {
    await test();
  }, environment: {
    Environment.hostnameKey: hostname,
    Environment.domainKey: domain,
    Environment.domainWildcardKey: '$wildcard',
    Environment().productionKey: '$production',
  });
}

// Future<void> _runAcquire(
//     {required String hostname,
//     required String domain,
//     bool wildcard = false,
//     bool production = false,
//     bool revoke = true}) async {
//   Certbot().clearBlockFlag();

//   if (revoke) {
//     _revokeAll();
//   }

//   AcquisitionManager().enterAcquisitionMode(reload: false);

//   /// acquire the certificate
//   await AcquisitionManager().acquireIfRequired(reload: false);

//   expect(AcquisitionManager().inAcquisitionMode, equals(false));
//   expect(Certbot().hasValidCertificate(), equals(true));

//   expect(Certbot().isDeployed(), equals(true));
//   expect(
//       Certbot().wasIssuedFor(
//           hostname: hostname,
//           domain: domain,
//           wildcard: wildcard,
//           production: production),
//       equals(true));

//   if (revoke) {
//     final cert = Certificate.find(
//         hostname: hostname,
//         domain: domain,
//         wildcard: wildcard,
//         production: production)!;

//     expect(cert, equals(isNotNull));

//     cert.revoke();
//   }
// }

// void _revokeAll() {
//   Certbot().deleteInvalidCertificates(
//       hostname: Environment().hostname!,
//       domain: Environment().domain,
//       wildcard: Environment().domainWildcard,
//       production: Environment().production);

//   for (final certificate in Certbot().certificates()) {
//     certificate!.revoke();
//   }
//   expect(Certbot().hasValidCertificate(), equals(false));
//   expect(Certbot().isDeployed(), equals(false));
// }

void configMockDeployHook() {
  const path = 'test/src/util/mock_deploy_hook';
  if (!exists(path)) {
    DartScript.fromFile('$path.dart').compile();
  }

  Environment().certbotDeployHookPath = path;
}
