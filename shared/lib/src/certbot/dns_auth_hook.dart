#! /usr/bin/env dshell
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/src/namecheap/challenge.dart';
import 'package:nginx_le_shared/src/namecheap/env.dart';

import 'certbot.dart';

///
/// This app is called by Certbot to provide the DNS validation.
///
/// This app creates a DNS TXT record _acme-challenge containing the validation
/// key.
/// The app then loops until the TXT record is propergated to local DNS servers.
///
/// Once the TXT record is available we return an let
///
void certbot_dns_auth_hook() {
  Certbot().log('*' * 80);
  Certbot().log('certbot_dns_auth_hook started');

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

  // ignore: unnecessary_cast
  var certbotAuthKey = env('CERTBOT_VALIDATION') as String;
  Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
  if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
    Certbot().logError(
        'The environment variable CERTBOT_VALIDATION was empty dns_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotAuthKey, 'The environment variable CERTBOT_VALIDATION was empty');

  /// our own envs.
  var domain = env('DOMAIN');
  Certbot().log('DOMAIN: $domain');
  var hostname = env('HOSTNAME');
  Certbot().log('HOSTNAME: $hostname');
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
    if ((challenge.present(
        hostname: hostname,
        domain: domain,
        tld: tld,
        certbotAuthKey: certbotAuthKey))) {
      Certbot().log('createDNSChallenged SUCCESS');
    } else {
      Certbot().log('createDNSChallenged failed');
    }
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('certbot_dns_auth_hook completed');
  Certbot().log('*' * 80);
}
