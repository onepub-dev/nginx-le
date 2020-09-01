import 'dart:io';

import 'package:dcli/dcli.dart' hide equals;
@Timeout(Duration(minutes: 30))
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/dns_auth_providers.dart';
import 'package:test/test.dart';

import 'dns_auth_hook_test.dart';

void main() {
  test('acquire', () {
    prepareCertHooks();

    var apiKey = ask('Namecheap api key');
    var username = ask('Namecheap api username');
    // pass the security details down to the createDNSChallenge.dart process
    Environment().namecheapApiUser = username;
    Environment().namecheapApiKey = apiKey;

    var authProvider = DnsAuthProviders().getByName('namecheap');

    authProvider.promptForSettings(ConfigYaml());
    Environment().hostname = 'slayer';

    Environment().domain = 'noojee.org';
    Environment().tld = 'org';
    Environment().emailaddress = 'bsutton@noojee.com.au';
    Environment().mode = 'private';
    Environment().staging = true;

    authProvider.acquire();

    Certbot().revoke(hostname: 'slayer', domain: 'noojee.org', staging: true);

    authProvider.acquire();

    Certbot().revoke(hostname: 'slayer', domain: 'noojee.org', staging: true);
  });

  test('parse', () {
    var path = Directory('/tmp').createTempSync().path;

    Environment().certbotRoot = path;
    createDir(join(Certbot.letsEncryptConfigPath, 'live', 'robtest18-new.clouddialer.com.au'), recursive: true);
    var fqnd001 = join(Certbot.letsEncryptConfigPath, 'live', 'robtest18-new.clouddialer.com.au-0001');
    createDir(fqnd001, recursive: true);

    // noojee.org-0001
    // noojee.org-new
    // noojee.org-new-0001
    var latest = Certbot().latestCertificatePath('robtest18-new', 'clouddialer.com.au');
    expect(latest, equals(fqnd001));

    // createDir(join(path, 'robtest18.clouddialer.com.au'));
  });
}
