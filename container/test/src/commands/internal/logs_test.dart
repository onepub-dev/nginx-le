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
import 'package:test/test.dart';

import '../../with_test_environment.dart';

void main() {
  test('Log Command -no follow - all default logfiles', () async {
    await withTestEnvironment(() async {
      Nginx.accesslogpath.append('Hellow world');

      await logs([
        '--debug',
      ]);
    });
  });

  test('Log Command - no follow - just access logfile.', () async {
    await withTestEnvironment(() async {
      Nginx.accesslogpath.append('Hellow world');

      await logs([
        '--access',
        '--debug',
      ]);
    });
  });

  test('Log Command - no follow - just access and error logfile.', () async {
    await withTestEnvironment(() async {
      Nginx.accesslogpath.append('Hellow world');

      await logs([
        '--access',
        '--error',
        '--debug',
      ]);
    });
  });

  test('Log Command - follow -  accesslogfile.', () async {
    await withTestEnvironment(() async {
      Nginx.accesslogpath.append('Hellow world');

      await logs(['--access', '--debug', '--follow']);
    });

    /// can't run this as the command will run forever.
  }, skip: true);
}
