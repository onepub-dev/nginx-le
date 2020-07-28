@Timeout(Duration(minutes: 60))
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/certbot/http_auth_hook.dart';
import 'package:nginx_le_shared/src/certbot/http_cleanup_hook.dart';
import 'package:test/test.dart';

void main() {
  test('http_auth_hook', () {
    Settings().setVerbose(enabled: true);
    prepareCertHooks();

    certbot_http_auth_hook();
  });

  test('http_cleanup_hook', () {
    Settings().setVerbose(enabled: true);

    prepareCertHooks();

    certbot_http_cleanup_hook();
  });
}

void prepareCertHooks() {
  var letsencryptDir = '/tmp/letsencrypt';
  setEnv(Certbot.LETSENCRYPT_ROOT_ENV, letsencryptDir);
  setEnv('CERTBOT_DOMAIN', 'noojee.org');
  setEnv('TLD', 'org');
  setEnv('MODE', 'private');
  setEnv('CERTBOT_VALIDATION', 'TEST_TOKEN_ABC134');
  setEnv('CERTBOT_TOKEN', 'token_file');

  setEnv(Certbot.NGINX_CERT_ROOT_OVERWRITE, '/tmp/nginx/certs');
  _createDir(Certbot.nginxCertPath);

  _createDir(Certbot.letsEncryptWorkPath);
  _createDir(Certbot.letsEncryptLogPath);
  _createDir(Certbot.letsEncryptConfigPath);
  _createDir(join(Certbot.letsEncryptConfigPath, 'live'));

  print(pwd);
  setEnv(
      'CERTBOT_HTTP_AUTH_HOOK_PATH',
      // 'dshell ../container/bin/certbot_hooks/dns_auth.dart',
      'http_auth');
  setEnv(
      'CERTBOT_HTTP_CLEANUP_HOOK_PATH',
      // 'dshell ../container/bin/certbot_hooks/dns_cleanup.dart',
      'http_cleanup');
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
