@Timeout(Duration(minutes: 60))
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/http_auth/http_auth_hook.dart';
import 'package:nginx_le_shared/src/auth_providers/http_auth/http_cleanup_hook.dart';
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
  Environment().certbotRoot = letsencryptDir;
  Environment().certbotDomain = 'noojee.org';
  Environment().tld = 'org';
  Environment().mode = 'private';
  Environment().certbotValidation = 'TEST_TOKEN_ABC134';
  Environment().certbotToken = 'token_file';

  Environment().certbotRootPathOverwrite = '/tmp/nginx/certs';
  _createDir(Certbot.nginxCertPath);

  _createDir(Certbot.letsEncryptWorkPath);
  _createDir(Certbot.letsEncryptLogPath);
  _createDir(Certbot.letsEncryptConfigPath);
  _createDir(join(Certbot.letsEncryptConfigPath, 'live'));

  print(pwd);
  Environment().certbotDNSAuthHookPath = 'http_auth';
  Environment().certbotDNSCleanupHookPath = 'http_cleanup';
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
