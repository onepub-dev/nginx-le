/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

void prepareEnvironment() {
  const letsencryptDir = '/tmp/letsencrypt';
  Environment().certbotRootPath = letsencryptDir;
  Environment().certbotDomain = 'noojee.org';
  Environment().tld = 'org';
  Environment().certbotValidation = 'TEST_TOKEN_ABC134';
  Environment().certbotToken = 'token_file';
  Environment().nginxAccessLogPath = '/tmp/nginx/access.log';
  Environment().nginxErrorLogPath = '/tmp/nginx/error.log';

  Environment().nginxCertRootPathOverwrite = '/tmp/nginx/certs';
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
