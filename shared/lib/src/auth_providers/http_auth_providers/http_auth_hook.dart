#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

import '../../../nginx_le_shared.dart';

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
  var verbose = Environment().certbotVerbose;
  Certbot().log('verbose: $verbose');
  print('VERBOSE=$verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  var fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');
  Certbot().log('CERTBOT_TOKEN: ${Environment().certbotToken}');
  print('CERTBOT_TOKEN: ${Environment().certbotToken}');
  Certbot().log('CERTBOT_VALIDATION: ${Environment().certbotValidation}');
  print('CERTBOT_VALIDATION: ${Environment().certbotValidation}');

  // ignore: unnecessary_cast
  var certbotAuthKey = Environment().certbotValidation;
  Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
  if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
    Certbot().logError(
        'The environment variable CERTBOT_VALIDATION was empty http_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotAuthKey, 'The environment variable CERTBOT_VALIDATION was empty');

  var token = Environment().certbotToken;
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