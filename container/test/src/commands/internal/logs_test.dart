@Timeout(Duration(minutes: 10))
import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/commands/internal/logs.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  test('Log Command -no tail - all default logfiles', () {
    setup();

    Settings().setVerbose(enabled: true);
    Nginx.accesslogpath.append('Hellow world');

    logs([
      '--debug',
      '--no-tail',
    ]);
  });

  test('Log Command - no tail - just access logfile.', () {
    setup();

    Settings().setVerbose(enabled: true);
    Nginx.accesslogpath.append('Hellow world');

    logs([
      '--access',
      '--debug',
      '--no-tail',
    ]);
  });

  test('Log Command - no tail - just access and error logfile.', () {
    setup();

    Settings().setVerbose(enabled: true);
    Nginx.accesslogpath.append('Hellow world');

    logs([
      '--access',
      '--error',
      '--debug',
      '--no-tail',
    ]);
  });

  test('Log Command - tail -  accesslogfile.', () {
    setup();

    Settings().setVerbose(enabled: true);
    Nginx.accesslogpath.append('Hellow world');

    logs([
      '--access',
      '--debug',
    ]);
  });
}

void setup() {
  Environment().certbotRootPath = '/tmp/letsencrypt';
  if (!exists(CertbotPaths().letsEncryptRootPath)) {
    createDir(CertbotPaths().letsEncryptRootPath);
  }

  if (!exists(CertbotPaths().letsEncryptLogPath)) {
    createDir(CertbotPaths().letsEncryptRootPath);
  }

  touch(join(CertbotPaths().letsEncryptLogPath, CertbotPaths().LOG_FILE_NAME),
      create: true);

  Environment().nginxAccessLogPath = '/tmp/nginx/access.log';
  Environment().nginxErrorLogPath = '/tmp/nginx/error.log';

  if (!exists(dirname(Nginx.accesslogpath))) {
    createDir(dirname(Nginx.accesslogpath), recursive: true);
  }
  touch(join(Nginx.accesslogpath), create: true);
  touch(join(Nginx.errorlogpath), create: true);
}
