@Timeout(Duration(minutes: 10))
library;

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/commands/internal/logs.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('Log Command -no follow - all default logfiles', () async {
    setup();

    Nginx.accesslogpath.append('Hellow world');

    await logs([
      '--debug',
    ]);
  });

  test('Log Command - no follow - just access logfile.', () async {
    setup();

    Nginx.accesslogpath.append('Hellow world');

    await logs([
      '--access',
      '--debug',
    ]);
  });

  test('Log Command - no follow - just access and error logfile.', () async {
    setup();

    Nginx.accesslogpath.append('Hellow world');

    await logs([
      '--access',
      '--error',
      '--debug',
    ]);
  });

  test('Log Command - follow -  accesslogfile.', () async {
    setup();

    Nginx.accesslogpath.append('Hellow world');

    await logs(['--access', '--debug', '--follow']);

    /// can't run this as the command will run forever.
  }, skip: true);
}

void setup() {
  final testingDir = createTempDir();
  Environment().certbotRootPath = join(testingDir, 'letsencrypt');
  if (!exists(CertbotPaths().letsEncryptRootPath)) {
    createDir(CertbotPaths().letsEncryptRootPath);
  }

  if (!exists(CertbotPaths().letsEncryptLogPath)) {
    createDir(CertbotPaths().letsEncryptLogPath);
  }

  touch(join(CertbotPaths().letsEncryptLogPath, CertbotPaths().logFilename),
      create: true);

  Environment().nginxAccessLogPath = join(testingDir, 'access.log');
  Environment().nginxErrorLogPath = join(testingDir, 'error.log');

  if (!exists(dirname(Nginx.accesslogpath))) {
    createDir(dirname(Nginx.accesslogpath), recursive: true);
  }
  touch(join(Nginx.accesslogpath), create: true);
  touch(join(Nginx.errorlogpath), create: true);
}
