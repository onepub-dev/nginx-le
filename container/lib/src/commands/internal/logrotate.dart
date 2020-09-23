import 'package:dcli/dcli.dart';
import 'package:isolate/isolate_runner.dart';

const CONFIG_FILE = '/etc/nginx/logrotate.conf';
void logrotate() {
  print('Running logrotate');

  if (!exists(CONFIG_FILE)) {
    printerr(
        red('The logrotate configuration file was not found at: $CONFIG_FILE'));
  }
  'logrotate $CONFIG_FILE'.run;
}

////////////////////////////////////////////
/// Logrotate thread
////////////////////////////////////////////
void startLogRotateThread({bool debug = false}) {
  print('Starting the logrotate  scheduler.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(startScheduler, debug ? 'debug' : 'nodebug');
  } finally {
    waitForEx(iso.close());
  }
}

/// Isolate callback must be a top level function.
void startScheduler(String debug) {
  Settings().setVerbose(enabled: debug == 'debug');

  /// keep the isolate running forever.
  while (true) {
    /// we do a log rotation every 20 minutes.
    sleep(1200, interval: Interval.seconds);

    logrotate();
  }
}
