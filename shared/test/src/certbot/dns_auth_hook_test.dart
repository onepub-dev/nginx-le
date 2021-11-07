@Timeout(Duration(minutes: 60))
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_auth_provider.dart';
import 'package:test/test.dart';

/// You must run this test app in vscode with the console option.
void main() {
  Settings().setVerbose(enabled: true);
  prepareCertHooks();

  Certbot().sendToStdout();

  var provider = AuthProviders().getByName(NameCheapAuthProvider().name)!;
  provider.authHook();
}

void prepareCertHooks() {
  var letsencryptDir = '/tmp/letsencrypt';

  Environment().production = false;
  Environment().certbotRootPath = letsencryptDir;
  Environment().certbotDomain = 'noojee.org';
  Environment().hostname = 'slayer';
  Environment().domain = 'noojee.org';
  Environment().tld = 'org';
  Environment().domainWildcard = false;
  Environment().certbotValidation = 'TEST_TOKEN_ABC134';
  Environment().nginxCertRootPathOverwrite = '/tmp/nginx/certs';
  Environment().authProvider = NameCheapAuthProvider().name;

  _createDir(CertbotPaths().nginxCertPath);

  _createDir(CertbotPaths().letsEncryptWorkPath);
  _createDir(CertbotPaths().letsEncryptLogPath);
  _createDir(CertbotPaths().letsEncryptConfigPath);
  _createDir(join(CertbotPaths().letsEncryptLivePath));

  print(pwd);
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
