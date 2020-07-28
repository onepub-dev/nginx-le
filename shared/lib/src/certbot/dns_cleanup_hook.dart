import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/src/namecheap/challenge.dart';
import 'package:nginx_le_shared/src/namecheap/env.dart';

import 'certbot.dart';

void certbot_dns_cleanup_hook() {
  Certbot().log('*' * 80);
  Certbot().log('cert_bot_dns_cleanup_hook started');

  ///
  /// Get the environment vars passed to use
  ///
  var verbose = env('VERBOSE') == 'true';
  Certbot().log('verbose: $verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = env('CERTBOT_DOMAIN') as String;
  Certbot().log('fqdn: $fqdn');

  var certbotAuthKey = env('CERTBOT_VALIDATION');
  Certbot().log('CertbotAuthKey: $certbotAuthKey');

  /// our own envs.
  var domain = env('DOMAIN');
  var hostname = env('HOSTNAME');
  var tld = env('TLD');
  Certbot().log('tld: $tld');
  var username = env(NAMECHEAP_API_USER);
  Certbot().log('username: $username');
  var apiKey = env(NAMECHEAP_API_KEY);
  Certbot().log('apiKey: $apiKey');

  if (fqdn == null || fqdn.isEmpty) {
    printerr('Throwing exception: fqdn is empty');
    throw ArgumentError('No fqdn found in env var CERTBOT_DOMAIN');
  }

  try {
    ///
    /// Create the required DNS entry for the Certbot challenge.
    ///
    Settings().verbose('Creating challenge');
    var challenge = Challenge.simple(
        apiKey: apiKey, username: username, apiUsername: username);
    Settings().verbose('calling challenge.present');

    ///
    /// Writes the DNS record and waits for it to be visible.
    ///
    challenge.cleanUp(
        hostname: hostname,
        domain: domain,
        tld: tld,
        certbotAuthKey: certbotAuthKey);
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('cert_bot_dns_cleanup_hook completed');
  Certbot().log('*' * 80);
}
