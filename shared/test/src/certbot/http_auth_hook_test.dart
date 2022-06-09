@Timeout(Duration(minutes: 60))
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */



import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

import '../util/prepare.dart';

void main() {
  test('http_auth_hook', () {
    Settings().setVerbose(enabled: true);

    prepareEnvironment();

    HTTPAuthProvider().authHook();
  });

  test('http_cleanup_hook', () {
    Settings().setVerbose(enabled: true);

    prepareEnvironment();

    HTTPAuthProvider().cleanupHook();
  });
}
