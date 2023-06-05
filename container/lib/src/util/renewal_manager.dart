/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:isolates/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class RenewalManager {
////////////////////////////////////////////
  /// Renewal thread
////////////////////////////////////////////
  Future<void> start() async {
    print('Starting the certificate renewal scheduler.');

    // ignore: discarded_futures
    final iso = await IsolateRunner.spawn();

    try {
      unawaited(iso.run(startScheduler, Env().toJson()));
    } finally {
      // ignore: discarded_futures
      await iso.close();
    }
  }
}

/// Isolate callback must be a top level function.
Future<void> startScheduler(String environment) async {
  sleep(15);

  /// We do an immediate renew attempt incase this service hasn't run
  /// for a while and its certificate has expired.
  Certbot().renew();

  try {
    print(orange('RenewManager is starting'));
    Env().fromJson(environment);
    Settings().setVerbose(enabled: Environment().debug);
    // ngix is running we now need to start the certbot renew scheduler.
    Certbot().scheduleRenews();

    /// keep the isolate running forever.
    while (true) {
      Settings().setVerbose(enabled: false);
      sleep(10);
      Settings().setVerbose(enabled: Environment().debug);
    }
    // ignore: avoid_catches_without_on_clauses
  } catch (e, st) {
    printerr(red('RenewalManager has shutdown due to an unexpected '
        'error: ${e.runtimeType}'));
    printerr(e.toString());
    printerr(st.toString());
    await Email.sendError(subject: e.toString(), body: st.toString());
  } finally {
    print(orange('RenewManager has shut down.'));
  }
}
