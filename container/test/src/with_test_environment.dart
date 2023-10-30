/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:path/path.dart';

Future<void> withTestEnvironment(void Function() action) async {
  withTempDir((tempDir) {
    final letsencryptDir = join(tempDir, 'letsencrypt');
    Environment().certbotRootPath = letsencryptDir;
    Environment().certbotDomain = 'squarephone.biz';
    Environment().tld = 'org';
    Environment().certbotValidation = 'TEST_TOKEN_ABC134';
    Environment().certbotToken = 'token_file';
    Environment().nginxAccessLogPath = join(tempDir, 'nginx', 'access.log');
    Environment().nginxErrorLogPath = join(tempDir, 'nginx', 'error.log');

    Environment().nginxCertRootPathOverwrite = join(tempDir, 'nginx', 'certs');
    _createDir(CertbotPaths().nginxCertPath);
    _createDir(CertbotPaths().letsEncryptRootPath);
    _createDir(CertbotPaths().letsEncryptWorkPath);
    _createDir(CertbotPaths().letsEncryptLogPath);
    _createDir(CertbotPaths().letsEncryptConfigPath);
    _createDir(join(CertbotPaths().letsEncryptLivePath));

    action();
  });
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
