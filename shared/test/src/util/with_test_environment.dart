/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli_core/dcli_core.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:path/path.dart';

Future<void> withTestEnvironment(void Function() action) async {
  await withTempDir((tempDir) async {
    final letsencryptDir = join(tempDir, 'letsencrypt');
    Environment().certbotRootPath = letsencryptDir;
    Environment().certbotDomain = 'squarephone.biz';
    Environment().tld = 'org';
    Environment().certbotValidation = 'TEST_TOKEN_ABC134';
    Environment().certbotToken = 'token_file';
    Environment().nginxAccessLogPath = join(tempDir, 'nginx', 'access.log');
    Environment().nginxErrorLogPath = join(tempDir, 'nginx', 'error.log');

    Environment().nginxCertRootPathOverwrite = join(tempDir, 'nginx', 'certs');
    await lcreateDir(CertbotPaths().nginxCertPath);
    await lcreateDir(CertbotPaths().letsEncryptRootPath);
    await lcreateDir(CertbotPaths().letsEncryptWorkPath);
    await lcreateDir(CertbotPaths().letsEncryptLogPath);
    await lcreateDir(CertbotPaths().letsEncryptConfigPath);
    await lcreateDir(join(CertbotPaths().letsEncryptLivePath));

    action();
  });
}

Future<String> lcreateDir(String dir) async {
  if (!exists(dir)) {
    await createDir(dir, recursive: true);
  }
  return dir;
}
