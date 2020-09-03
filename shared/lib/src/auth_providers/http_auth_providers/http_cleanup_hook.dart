import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

import '../../certbot/certbot.dart';

void certbot_http_cleanup_hook() {
  Certbot().log('*' * 80);
  Certbot().log('cert_bot_http_cleanup_hook started');

  ///
  /// Get the environment vars passed to use
  ///
  var verbose = Environment().certbotVerbose;
  Certbot().log('verbose: $verbose');

  Settings().setVerbose(enabled: verbose);
  ArgumentError.checkNotNull(
      Environment().certbotToken, 'The environment variable ${Environment().certbotTokenKey} was empty');

  /// This path MUST match the path set in the nginx config files:
  /// /etc/nginx/custom/default.conf
  /// /etc/nginx/acquire/default.conf
  var path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known', Environment().certbotToken);
  if (exists(path)) {
    delete(path);
  }

  Certbot().log('cert_bot_http_cleanup_hook completed');
  Certbot().log('*' * 80);
}
