@Timeout(Duration(minutes: 10))
import 'package:dshell/dshell.dart';
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
  setEnv(Certbot.LETSENCRYPT_ROOT_ENV, '/tmp/letsencrypt');
  if (!exists(Certbot.letsEncryptRootPath)) {
    createDir(Certbot.letsEncryptRootPath);
  }

  if (!exists(Certbot.letsEncryptLogPath)) {
    createDir(Certbot.letsEncryptRootPath);
  }

  touch(join(Certbot.letsEncryptLogPath, Certbot.LOG_FILE_NAME), create: true);

  setEnv(Nginx.NGINX_ACCESS_LOG_ENV, '/tmp/nginx/access.log');
  setEnv(Nginx.NGINX_ERROR_LOG_ENV, '/tmp/nginx/error.log');

  if (!exists(dirname(Nginx.accesslogpath))) {
    createDir(dirname(Nginx.accesslogpath), recursive: true);
  }
  touch(join(Nginx.accesslogpath), create: true);
  touch(join(Nginx.errorlogpath), create: true);
}
