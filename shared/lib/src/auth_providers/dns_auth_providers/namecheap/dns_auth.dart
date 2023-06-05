#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';

import '../../../../nginx_le_shared.dart';
import 'challenge.dart';
import 'namecheap_auth_provider.dart';

///
/// This app is called by Certbot to provide the DNS validation.
///
/// This app creates a DNS TXT record _acme-challenge containing the validation
/// key.
/// The app then loops until the TXT record is propergated to local DNS servers.
///
/// Once the TXT record is available we return an let
///
Future<void> namecheapDNSPath() async {
  Certbot().log('*' * 80);
  Certbot().log('certbot_dns_auth started');

  ///
  /// Get the environment vars passed to use
  ///
  final isVerbose = Environment().certbotVerbose;
  Certbot().log('verbose: $isVerbose');

  Settings().setVerbose(enabled: isVerbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  final fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');

  // ignore: unnecessary_cast
  final certbotValidation = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: "$certbotValidation"');

  if (certbotValidation == null || certbotValidation.isEmpty) {
    Certbot().logError(
        'The environment variable ${Environment.certbotValidationKey} '
        'was empty dns_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotValidation,
      'The environment variable ${Environment.certbotValidationKey} '
      'was empty');

  final authProvider = AuthProviders().getByName(NameCheapAuthProvider().name)!;

  /// our own envs.
  final domain = Environment().domain;
  Certbot().log('${Environment.domainKey}: $domain');
  final hostname = Environment().hostname;
  Certbot().log('${Environment.hostnameKey}: $hostname');

  final tld = Environment().tld;
  if (tld == null || tld.isEmpty) {
    printerr('Throwing exception: tld is empty');
    throw ArgumentError('No tld found in env var ${Environment.tldKey}');
  }

  Certbot().log('tld: $tld');
  final wildcard = Environment().domainWildcard;
  Certbot().log('wildcard: $wildcard');

  final username = authProvider.envUsername;
  Certbot().log('username: $username');
  final apiKey = authProvider.envToken;
  Certbot().log('apiKey: $apiKey');

  /// the number of times we look to see if the DNS challenge is resolving.
  final retries = Environment().certbotDNSRetries;
  Certbot().log('${Environment.certbotDNSRetriesKey}: $retries');

  if (fqdn == null || fqdn.isEmpty) {
    printerr('Throwing exception: fqdn is empty');
    throw ArgumentError(
        'No fqdn found in env var ${Environment.certbotDomainKey}');
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
    if (await challenge.present(
        hostname: hostname,
        domain: domain,
        tld: tld,
        wildcard: wildcard,
        certbotValidationString: certbotValidation!,
        retries: retries)) {
      Certbot().log('createDNSChallenged SUCCESS');
    } else {
      Certbot().log('createDNSChallenged failed');
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    printerr(e.toString());
  }

  Certbot().log('certbot_dns_auth completed');
  Certbot().log('*' * 80);
}
