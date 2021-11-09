import 'package:dcli/dcli.dart';
import 'package:isolates/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

const configFilePathTo = '/etc/nginx/logrotate.conf';

////////////////////////////////////////////
/// Logrotate thread
////////////////////////////////////////////

class LogManager {
  late IsolateRunner isoLogRotate;

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
    print(orange('LogManager has shut down.'));
  }
}

void _logrotate() {
  if (!exists(configFilePathTo)) {
    printerr(red(
        'The logrotate configuration file was not found at: $configFilePathTo'));
  }
  if (start('logrotate $configFilePathTo',
              nothrow: true, progress: Progress.print())
          .exitCode !=
      0) {
    print(red('Logrotate exited with a non-zero exit code.'));
  }
}
