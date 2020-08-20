import 'package:dshell/dshell.dart';
@Timeout(Duration(minutes: 30))
import 'package:nginx_le_shared/nginx_le_shared.dart';
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

    Certbot().acquire(
        hostname: 'slayer',
        domain: 'noojee.org',
        tld: 'org',
        emailaddress: 'bsutton@noojee.com.au',
        mode: 'private',
        staging: true);

    Certbot().revoke(hostname: 'slayer', domain: 'noojee.org', staging: true);

    Certbot().acquire(
        hostname: 'slayer',
        domain: 'noojee.org',
        tld: 'org',
        emailaddress: 'bsutton@noojee.com.au',
        mode: 'private',
        staging: true);

    Certbot().revoke(hostname: 'slayer', domain: 'noojee.org', staging: true);
  });
}
