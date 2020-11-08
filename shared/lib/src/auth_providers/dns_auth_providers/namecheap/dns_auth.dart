#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_auth_provider.dart';

import 'challenge.dart';

///
/// This app is called by Certbot to provide the DNS validation.
///
/// This app creates a DNS TXT record _acme-challenge containing the validation
/// key.
/// The app then loops until the TXT record is propergated to local DNS servers.
///
/// Once the TXT record is available we return an let
///
void namecheap_dns_auth() {
  Certbot().log('*' * 80);
  Certbot().log('certbot_dns_auth started');

  ///
  /// Get the environment vars passed to use
  ///
  var verbose = Environment().certbotVerbose;
  Certbot().log('verbose: $verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');

  // ignore: unnecessary_cast
  var certbotValidation = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: "$certbotValidation"');

  if (certbotValidation == null || certbotValidation.isEmpty) {
    Certbot().logError(
        'The environment variable ${Environment().certbotValidationKey} was empty dns_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(certbotValidation,
      'The environment variable ${Environment().certbotValidationKey} was empty');

  var authProvider = AuthProviders().getByName(NameCheapAuthProvider().name);

  /// our own envs.
  var domain = Environment().domain;
  Certbot().log('${Environment().domainKey}: $domain');
  var hostname = Environment().hostname;
  Certbot().log('${Environment().hostnameKey}: $hostname');
  var tld = Environment().tld;
  Certbot().log('tld: $tld');
  var username = authProvider.envUsername;
  Certbot().log('username: $username');
  var apiKey = authProvider.envToken;
  Certbot().log('apiKey: $apiKey');

  /// the number of times we look to see if the DNS challenge is resolving.
  var retries = Environment().certbotDNSRetries;
  Certbot().log('${Environment().certbotDNSRetriesKey}: $retries');

  if (fqdn == null || fqdn.isEmpty) {
    printerr('Throwing exception: fqdn is empty');
    throw ArgumentError(
        'No fqdn found in env var ${Environment().certbotDomainKey}');
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
        certbotValidationString: certbotValidation,
        retries: retries))) {
      Certbot().log('createDNSChallenged SUCCESS');
    } else {
      Certbot().log('createDNSChallenged failed');
    }
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('certbot_dns_auth completed');
  Certbot().log('*' * 80);
}
