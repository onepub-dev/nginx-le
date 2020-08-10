#! /usr/bin/env dshell

import 'package:dshell/dshell.dart';

import 'certbot.dart';

///
/// This app is called by Certbot to provide the HTTP validation.
///
/// We simply create a validation file containing the passed token
/// in the nginx wellknown path.
///
///
void certbot_http_auth_hook() {
  Certbot().log('*' * 80);
  Certbot().log('certbot_http_auth_hook started');

  ///
  /// Get the environment vars passed to use
  ///
  var verbose = env('VERBOSE') == 'true';
  Certbot().log('verbose: $verbose');
  print('VERBOSE=$verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = env('CERTBOT_DOMAIN') as String;
  Certbot().log('fqdn: $fqdn');
  Certbot().log('CERTBOT_TOKEN: ${env('CERTBOT_TOKEN')}');
  print('CERTBOT_TOKEN: ${env('CERTBOT_TOKEN')}');
  Certbot().log('CERTBOT_VALIDATION: ${env('CERTBOT_TOKEN')}');
  print('CERTBOT_VALIDATION: ${env('CERTBOT_TOKEN')}');

  // ignore: unnecessary_cast
  var certbotAuthKey = env('CERTBOT_VALIDATION') as String;
  Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
  if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
    Certbot().logError(
        'The environment variable CERTBOT_VALIDATION was empty http_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotAuthKey, 'The environment variable CERTBOT_VALIDATION was empty');

  var token = env('CERTBOT_TOKEN');
  Certbot().log('token: "$token"');
  if (token == null || token.isEmpty) {
    Certbot().logError(
        'The environment variable CERTBOT_TOKEN was empty http_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotAuthKey, 'The environment variable CERTBOT_TOKEN was empty');

  /// This path MUST match the path set in the nginx config files:
  /// /etc/nginx/custom/default.conf
  /// /etc/nginx/acquire/default.conf
  var path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
      'acme-challenge', token);
  print('writing token to $path');
  Certbot().log('writing token to $path');
  path.write(certbotAuthKey);

  Certbot().log('certbot_http_auth_hook completed');
  Certbot().log('*' * 80);
}
