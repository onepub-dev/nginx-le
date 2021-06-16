import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

import '../../../../nginx_le_shared.dart';
import 'challenge.dart';
import 'namecheap_auth_provider.dart';

void namncheap_dns_cleanup() {
  Certbot().log('*' * 80);
  Certbot().log('cert_bot_dns_cleanup started');

  ///
  /// Get the environment vars passed to use
  ///
  var isVerbose = Environment().certbotVerbose;
  Certbot().log('isVerbose: $isVerbose');

  Settings().setVerbose(enabled: isVerbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');

  var wildcard = Environment().domainWildcard;
  Certbot().log('wildcard: $wildcard');

  var certbotAuthKey = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: $certbotAuthKey');

  var authProvider = AuthProviders().getByName(NameCheapAuthProvider().name)!;

  /// our own envs.
  var domain = Environment().domain!;
  var hostname = Environment().hostname;
  var tld = Environment().tld!;
  Certbot().log('tld: $tld');
  var username = authProvider.envUsername;
  Certbot().log('username: $username');
  var apiKey = authProvider.envToken;
  Certbot().log('apiKey: $apiKey');

  if (fqdn == null || fqdn.isEmpty) {
    printerr('Throwing exception: fqdn is empty');
    throw ArgumentError(
        'No fqdn found in env var ${Environment().certbotDomainKey}');
  }

  try {
    ///
    /// Create the required DNS entry for the Certbot challenge.
    ///
    verbose(() => 'Creating challenge');
    var challenge = Challenge.simple(
        apiKey: apiKey, username: username, apiUsername: username);
    verbose(() => 'calling challenge.present');

    ///
    /// Writes the DNS record and waits for it to be visible.
    ///
    challenge.cleanUp(
        hostname: hostname,
        domain: domain,
        tld: tld,
        wildcard: wildcard,
        certbotValidationString: certbotAuthKey);
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('cert_bot_dns_cleanup completed');
  Certbot().log('*' * 80);
}
