import 'package:dcli/dcli.dart';
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
}
