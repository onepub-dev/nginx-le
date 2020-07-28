import 'package:dshell/dshell.dart';

import 'certbot.dart';

void certbot_http_cleanup_hook() {
  Certbot().log('*' * 80);
  Certbot().log('cert_bot_http_cleanup_hook started');

  ///
  /// Get the environment vars passed to use
  ///
  var verbose = env('VERBOSE') == 'true';
  Certbot().log('verbose: $verbose');

  Settings().setVerbose(enabled: verbose);
  ArgumentError.checkNotNull(
      env('CERTBOT_TOKEN'), 'The environment variable CERTBOT_TOKEN was empty');

  /// This path MUST match the path set in the nginx config files:
  /// /etc/nginx/custom/default.conf
  /// /etc/nginx/acquire/default.conf
  var path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
      env('CERTBOT_TOKEN'));
  if (exists(path)) {
    delete(path);
  }

  Certbot().log('cert_bot_http_cleanup_hook completed');
  Certbot().log('*' * 80);
}
