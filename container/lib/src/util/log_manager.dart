import 'package:dcli/dcli.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

const CONFIG_FILE = '/etc/nginx/logrotate.conf';

////////////////////////////////////////////
/// Logrotate thread
////////////////////////////////////////////

class LogManager {
  IsolateRunner isoLogRotate;

  void start({bool debug = false}) {
    print('Starting the logrotate  scheduler.');

    isoLogRotate = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      isoLogRotate.run(_startScheduler, Env().toJson());
    } finally {
      waitForEx(isoLogRotate.close());
    }
  }
}

/// Isolate callback must be a top level function.
void _startScheduler(String environment) {
  try {
    print(orange('LogManager is starting'));
    Env().fromJson(environment);

    Settings().setVerbose(enabled: Environment().debug);

    /// keep the isolate running forever.
    while (true) {
      /// we do a log rotation every 20 minutes.
      sleep(1200, interval: Interval.seconds);

      _logrotate();
    }
  } catch (e, st) {
    printerr(red(
        'LogManager has shutdown due to an unexpected error: ${e.runtimeType}'));
    printerr(e.toString());
    printerr(st.toString());
    Email.sendError(subject: e.toString(), body: st.toString());
  } finally {
    print(orange('LogManager has shutting down.'));
  }
}

void _logrotate() {
  print('Running logrotate');

  if (!exists(CONFIG_FILE)) {
    printerr(
        red('The logrotate configuration file was not found at: $CONFIG_FILE'));
  }
  if (start('logrotate $CONFIG_FILE', nothrow: true, progress: Progress.print())
          .exitCode !=
      0) {
    print(red('Logrotate exited with a non-zero exit code.'));
  }
}
