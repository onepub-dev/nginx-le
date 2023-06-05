/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:isolates/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

const configFilePathTo = '/etc/nginx/logrotate.conf';

////////////////////////////////////////////
/// Logrotate thread
////////////////////////////////////////////

class LogManager {
  late IsolateRunner isoLogRotate;

  Future<void> start({bool debug = false}) async {
    print('Starting the logrotate  scheduler.');

    // ignore: discarded_futures
    isoLogRotate = await IsolateRunner.spawn();

    try {
      unawaited(isoLogRotate.run(_startScheduler, Env().toJson()));
    } finally {
      // ignore: discarded_futures
      await isoLogRotate.close();
    }
  }
}

/// Isolate callback must be a top level function.
Future<void> _startScheduler(String environment) async {
  try {
    print(orange('LogManager is starting'));
    Env().fromJson(environment);

    Settings().setVerbose(enabled: Environment().debug);

    /// keep the isolate running forever.
    while (true) {
      /// we do a log rotation every 20 minutes.
      sleep(1200);

      _logrotate();
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e, st) {
    printerr(red('LogManager has shutdown due to an unexpected '
        'error: ${e.runtimeType}'));
    printerr(e.toString());
    printerr(st.toString());
    await Email.sendError(subject: e.toString(), body: st.toString());
  } finally {
    print(orange('LogManager has shut down.'));
  }
}

void _logrotate() {
  if (!exists(configFilePathTo)) {
    printerr(red('The logrotate configuration file was not found '
        'at: $configFilePathTo'));
  }
  if (start('logrotate $configFilePathTo',
              nothrow: true, progress: Progress.print())
          .exitCode !=
      0) {
    print(red('Logrotate exited with a non-zero exit code.'));
  }
}
