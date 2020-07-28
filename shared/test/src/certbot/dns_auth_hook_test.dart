@Timeout(Duration(minutes: 60))
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

/// You must run this command with the console option.
void main() {
  test('dns_auth_hook', () {
    Settings().setVerbose(enabled: true);
    prepareCertHooks();

    setNameCheapAuthDetails();

    certbot_dns_auth_hook();
  });

  test('dns_cleanup_hook', () {
    Settings().setVerbose(enabled: true);

    prepareCertHooks();

    setNameCheapAuthDetails();

    certbot_dns_cleanup_hook();
  });
}

void prepareCertHooks() {
  var letsencryptDir = '/tmp/letsencrypt';
  setEnv(Certbot.LETSENCRYPT_ROOT_ENV, letsencryptDir);
  setEnv('CERTBOT_DOMAIN', 'noojee.org');
  setEnv('HOSTNAME', 'slayer');
  setEnv('DOMAIN', 'noojee.org');

  setEnv('TLD', 'org');
  setEnv('MODE', 'private');
  setEnv('CERTBOT_VALIDATION', 'TEST_TOKEN_ABC134');

  setEnv(Certbot.NGINX_CERT_ROOT_OVERWRITE, '/tmp/nginx/certs');
  _createDir(Certbot.nginxCertPath);

  _createDir(Certbot.letsEncryptWorkPath);
  _createDir(Certbot.letsEncryptLogPath);
  _createDir(Certbot.letsEncryptConfigPath);
  _createDir(join(Certbot.letsEncryptConfigPath, 'live'));

  print(pwd);
  setEnv(
      'CERTBOT_DNS_AUTH_HOOK_PATH',
      // 'dshell ../container/bin/certbot_hooks/dns_auth.dart',
      'dns_auth');
  setEnv(
      'CERTBOT_DNS_CLEANUP_HOOK_PATH',
      // 'dshell ../container/bin/certbot_hooks/dns_cleanup.dart',
      'dns_cleanup');

  setNameCheapAuthDetails();
}

void setNameCheapAuthDetails() {
  var apiKey = ask(prompt: 'Namecheap api key');
  var username = ask(prompt: 'Namecheap api username');
  // pass the security details down to the createDNSChallenge.dart process
  setEnv(NAMECHEAP_API_USER, username);
  setEnv(NAMECHEAP_API_KEY, apiKey);
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
