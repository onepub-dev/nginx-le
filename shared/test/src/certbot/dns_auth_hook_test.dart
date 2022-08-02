@Timeout(Duration(minutes: 60))
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_auth_provider.dart';
import 'package:test/test.dart';

/// You must run this test app in vscode with the console option.
void main() {
  Settings().setVerbose(enabled: true);
  prepareNameCheapCertHooks(
      hostname: 'slayer', domain: 'noojee.org', tld: 'org', wildcard: false);

  Certbot().sendToStdout();

  AuthProviders().getByName(NameCheapAuthProvider().name)!.authHook();
}

void prepareNameCheapCertHooks(
    {required String hostname,
    required String domain,
    required String tld,
    required bool wildcard}) {
  const letsencryptDir = '/tmp/letsencrypt';

  Environment().production = false;
  Environment().certbotRootPath = letsencryptDir;
  Environment().certbotDomain = domain;
  Environment().hostname = hostname;
  Environment().domain = domain;
  Environment().tld = tld;
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
