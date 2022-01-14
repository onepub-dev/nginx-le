import 'package:dcli/dcli.dart';

import '../../../../nginx_le_shared.dart';
import 'challenge.dart';
import 'namecheap_auth_provider.dart';

void namecheapDNSCleanup() {
  Certbot().log('*' * 80);
  Certbot().log('cert_bot_dns_cleanup started');

  ///
  /// Get the environment vars passed to use
  ///
  final isVerbose = Environment().certbotVerbose;
  Certbot().log('isVerbose: $isVerbose');

  Settings().setVerbose(enabled: isVerbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  final fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');

  final wildcard = Environment().domainWildcard;
  Certbot().log('wildcard: $wildcard');

  final certbotAuthKey = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: $certbotAuthKey');

  final authProvider = AuthProviders().getByName(NameCheapAuthProvider().name)!;

  /// our own envs.
  final domain = Environment().domain!;
  final hostname = Environment().hostname;
  final tld = Environment().tld!;
  Certbot().log('tld: $tld');
  final username = authProvider.envUsername;
  Certbot().log('username: $username');
  final apiKey = authProvider.envToken;
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
    final challenge = Challenge.simple(
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
  // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('cert_bot_dns_cleanup completed');
  Certbot().log('*' * 80);
}
