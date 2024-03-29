#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:dcli_core/dcli_core.dart' as core;
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/cloudflare/cloudflare_provider.dart';
import 'package:path/path.dart' hide equals;
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  group('certbot', () {
    setUpAll(() {
      if (which('auth_hook').notfound) {
        printerr(red('dcli compile -i -o container/bin/certbot_hooks/*.dart '
            'before running this test'));
        throw Exception(
            'run dcli compile -i -o container/bin/certbot_hooks/*.dart ');
      }
      print('setupall called');
      Environment().hostname = 'slayer';

      Environment().domain = 'squarephone.biz';
      Environment().tld = 'biz';
      Environment().emailaddress = 'bsutton@squarephone.biz';
      Environment().production = false;
      // Environment().certbotDNSAuthHookPath = '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/dns_auth.dart';
      // Environment().certbotDNSCleanupHookPath =
      //     '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/dns_cleanup.dart';
    });

    test('acquire', () {
      prepareCloudflareCertHooks(
          hostname: 'slayer',
          domain: 'squarephone.biz',
          tld: 'biz',
          wildcard: false);

      final authProvider =
          AuthProviders().getByName(CloudFlareProvider().name)!;
      print('acquire me');

      print('env ${env['CERTBOT_DNS_AUTH_HOOK_PATH']}');
      print('env ${env['CERTBOT_DNS_CLEANUP_HOOK_PATH']}');

      // // var apiKey = ask('Namecheap api key');
      // // var username = ask('Namecheap api username');
      // // pass the security details down to the createDNSChallenge.dart process
      // authProvider.envUsername = username;
      // authProvider.envToken = apiKey;

      final config = ConfigYaml();
      authProvider
        ..promptForSettings(config)
        ..envToken = authProvider.configToken
        ..envUsername = authProvider.configUsername
        ..acquire();

      var cert = Certificate.find(
        hostname: 'slayer',
        domain: 'squarephone.biz',
        production: false,
        wildcard: false,
      )!;
      expect(cert, equals(isNotNull));
      cert.revoke();

      authProvider.acquire();

      cert = Certificate.find(
        hostname: 'slayer',
        domain: 'squarephone.biz',
        production: false,
        wildcard: false,
      )!;
      expect(cert, equals(isNotNull));
      cert.revoke();
    }, timeout: const Timeout(Duration(minutes: 5)), skip: true);

    test(
        'renew - this can take > 10 min as certbot intentionally slows '
        'this call down.', () {
      prepareCloudflareCertHooks(
          hostname: 'slayer',
          domain: 'squarephone.biz',
          tld: 'biz',
          wildcard: false);

      final certificates = Certificate.load();

      for (final cert in certificates) {
        print(cert);
      }

      final authProvider =
          AuthProviders().getByName(CloudFlareProvider().name)!;

      print('renew');
      authProvider
        ..promptForSettings(ConfigYaml())
        ..envToken = authProvider.configToken
        ..envUsername = authProvider.configUsername;

      print(orange('calling acquire'));
      authProvider.acquire();

      print(orange('calling revoke'));
      Certificate.find(
              hostname: 'slayer',
              domain: 'squarephone.biz',
              production: false,
              wildcard: false)!
          .revoke();

      print(orange('calling acquire'));
      authProvider.acquire();

      print(orange('calling renew'));
      Certbot().renew();

      // print(orange('calling revoke'));
      // Certbot().revoke(
      //     hostname: 'slayer',
      //     domain: 'squarephone.biz',
      //     production: false,
      //     wildcard: false,
      //     emailaddress: Environment().emailaddress);
    }, timeout: const Timeout(Duration(minutes: 15)), tags: ['slow']);

    test('parse', () async {
      print('parse');

      await core.withTempDir((path) async {
        Environment().certbotRootPath = path;
        createDir(
            join(CertbotPaths().letsEncryptLivePath,
                'robtest18-new.squarephone.biz'),
            recursive: true);
        final fqnd001 = join(CertbotPaths().letsEncryptLivePath,
            'robtest18-new.squarephone.biz-0001');
        createDir(fqnd001, recursive: true);

        // squarephone.biz-0001
        // squarephone.biz-new
        // squarephone.biz-new-0001
        final latest = CertbotPaths().latestCertificatePath(
            'robtest18-new', 'squarephone.biz',
            wildcard: false);
        expect(latest, equals(fqnd001));

        // createDir(join(path, 'robtest18.squarephone.biz'));
      });
    });

    test('block flag', () {
      print('');
      //var flag = '/tmp/test.flag';
      //var flag = join(HOME, '.dcli');
      Environment().certbotRootPath = '/tmp';
      const flag = '/tmp/block_acquisitions.flag';

      touch(flag, create: true);
      final flagStat = stat(flag);
      print(flagStat.changed);
      print(flagStat.changed.add(const Duration(minutes: 15)));
      print(flagStat.changed
          .add(const Duration(minutes: 15))
          .isAfter(DateTime.now()));

      print('isblocked ${Certbot().isBlocked}');
    });
  });
}
