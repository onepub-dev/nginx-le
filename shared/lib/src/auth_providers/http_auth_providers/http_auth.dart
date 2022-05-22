#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

import '../../../nginx_le_shared.dart';

///
/// This app is called by Certbot to provide the HTTP validation.
///
/// We simply create a validation file containing the passed token
/// in the nginx wellknown path.
///
///
void certbotHTTPAuthHook() {
  Certbot().log('*' * 80);
  Certbot().log('certbot_http_auth_hook started');

  ///
  /// Get the environment vars passed to use
  ///
  final verbose = Environment().certbotVerbose;
  Certbot().log('verbose: $verbose');
  print('VERBOSE=$verbose');

  Settings().setVerbose(enabled: verbose);

  /// Certbot generated envs.
  // ignore: unnecessary_cast
  final fqdn = Environment().certbotDomain;
  Certbot().log('fqdn: $fqdn');
  Certbot()
      .log('${Environment.certbotTokenKey}: ${Environment().certbotToken}');
  print('${Environment.certbotTokenKey}: ${Environment().certbotToken}');
  Certbot().log('${Environment.certbotValidationKey}: '
      '${Environment().certbotValidation}');
  print('${Environment.certbotValidationKey}: '
      '${Environment().certbotValidation}');

  // ignore: unnecessary_cast
  final certbotValidation = Environment().certbotValidation;
  Certbot().log('${Environment.certbotValidationKey}: "$certbotValidation"');
  if (certbotValidation == null || certbotValidation.isEmpty) {
    Certbot().logError(
        'The environment variable ${Environment.certbotValidationKey} '
        'was empty http_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(
      certbotValidation,
      'The environment variable ${Environment.certbotValidationKey} '
      'was empty');

  final token = Environment().certbotToken;
  Certbot().log('token: "$token"');
  if (token == null || token.isEmpty) {
    Certbot()
        .logError('The environment variable ${Environment.certbotTokenKey} '
            'was empty http_auth_hook ABORTED.');
  }
  ArgumentError.checkNotNull(token,
      'The environment variable ${Environment.certbotTokenKey} was empty');

  /// This path MUST match the path set in the nginx config files:
  /// /etc/nginx/operating/default.conf
  /// /etc/nginx/acquire/default.conf
  final path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
      'acme-challenge', token);
  print('writing token to $path');
  Certbot().log('writing token to $path');
  path.write(token!);

  Certbot().log('certbot_http_auth_hook completed');
  Certbot().log('*' * 80);
}
