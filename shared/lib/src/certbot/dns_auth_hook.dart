#! /usr/bin/env dshell

import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/namecheap/challenge.dart';

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
  var verbose = Environment().certbotVerbose;
  Certbot().log('verbose: $verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');

  // ignore: unnecessary_cast
  var certbotAuthKey = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
  if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
    Certbot().logError(
        'The environment variable CERTBOT_VALIDATION was empty dns_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotAuthKey, 'The environment variable CERTBOT_VALIDATION was empty');

  /// our own envs.
  var domain = Environment().domain;
  Certbot().log('DOMAIN: $domain');
  var hostname = Environment().hostname;
  Certbot().log('HOSTNAME: $hostname');
  var tld = Environment().tld;
  Certbot().log('tld: $tld');
  var username = Environment().namecheapApiUser;
  Certbot().log('username: $username');
  var apiKey = Environment().namecheapApiKey;
  Certbot().log('apiKey: $apiKey');

  /// the number of times we look to see if the DNS challenge is resolving.
  var retries = Environment().certbotDNSRetries;
  Certbot().log('DNS_RETRIES: $retries');

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
        certbotAuthKey: certbotAuthKey,
        retries: retries))) {
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
