#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/commands/internal/service.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts the ngix docker instance using the host subdirectory 'certs' to store acquired certificates.
void main() {
  env['DEBUG'] = 'false';
  env['HOSTNAME'] = 'auditor';
  env['DOMAIN'] = 'noojee.com.au';
  env['TLD'] = 'com.au';
  env['EMAIL_ADDRESS'] = 'support@noojee.com.au';
  env['PRODUCTION'] = 'true';
  env['DOMAIN_WILDCARD'] = 'false';
  env['AUTO_ACQUIRE'] = 'true';
  env['SMTP_SERVER'] = 'noc-gcp.clouddialer.com.au';
  env['SMTP_SERVER_PORT'] = '25';
  env['START_PAUSED'] = 'false';
  env['AUTH_PROVIDER'] = 'HTTP01Auth';

  env['CERTBOT_HTTP_AUTH_HOOK_PATH'] = '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/http_auth.dart';
  env['CERTBOT_HTTP_CLEANUP_HOOK_PATH'] = '/home/bsutton/git/nginx-le/container/bin/certbot_hooks/http_cleanup.dart';

  print('email: ${Environment().emailaddress}');

  start_service();
}
