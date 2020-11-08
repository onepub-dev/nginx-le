@Timeout(Duration(minutes: 60))
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  test('http_auth_hook', () {
    Settings().setVerbose(enabled: true);

    prepareCertHooks();

    var provider = HTTPAuthProvider();
    provider.auth_hook();
  });

  test('http_cleanup_hook', () {
    Settings().setVerbose(enabled: true);

    prepareCertHooks();

    var provider = HTTPAuthProvider();
    provider.cleanup_hook();
  });
}

void prepareCertHooks() {
  var letsencryptDir = '/tmp/letsencrypt';
  Environment().certbotRootPath = letsencryptDir;
  Environment().certbotDomain = 'noojee.org';
  Environment().tld = 'org';
  Environment().certbotValidation = 'TEST_TOKEN_ABC134';
  Environment().certbotToken = 'token_file';

  Environment().nginxCertRootPathOverwrite = '/tmp/nginx/certs';
  _createDir(Certbot.nginxCertPath);

  _createDir(Certbot.letsEncryptWorkPath);
  _createDir(Certbot.letsEncryptLogPath);
  _createDir(Certbot.letsEncryptConfigPath);
  _createDir(join(Certbot.letsEncryptConfigPath, 'live'));

  print(pwd);
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
