@Timeout(Duration(minutes: 60))
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

/// You must run this command with the console option.
void main() {
  Settings().setVerbose(enabled: true);
  prepareCertHooks();

  Certbot().sendToStdout();

  certbot_dns_auth_hook();
}

void prepareCertHooks() {
  var letsencryptDir = '/tmp/letsencrypt';

  Environment().certbotRoot = letsencryptDir;
  Environment().certbotDomain = 'noojee.org';
  Environment().hostname = 'slayer';
  Environment().domain = 'noojee.org';
  Environment().tld = 'org';
  Environment().mode = 'private';
  Environment().certbotValidation = 'TEST_TOKEN_ABC134';
  Environment().certbotRootPathOverwrite = '/tmp/nginx/certs';

  _createDir(Certbot.nginxCertPath);

  _createDir(Certbot.letsEncryptWorkPath);
  _createDir(Certbot.letsEncryptLogPath);
  _createDir(Certbot.letsEncryptConfigPath);
  _createDir(join(Certbot.letsEncryptConfigPath, 'live'));

  print(pwd);
  Environment().certbotDNSAuthHookPath = 'dns_auth';
  Environment().certbotDNSCleanupHookPath = 'dns_cleanup';

  setNameCheapAuthDetails();
}

void setNameCheapAuthDetails() {
  var apiKey = ask('Namecheap api key');
  var username = ask('Namecheap api username');
  // pass the security details down to the createDNSChallenge.dart process
  Environment().namecheapApiUser = username;
  Environment().namecheapApiKey = apiKey;
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
