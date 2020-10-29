import 'package:dcli/dcli.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class RenewalManager {
////////////////////////////////////////////
  /// Renewal thread
////////////////////////////////////////////
  void start() {
    print('Starting the certificate renewal scheduler.');

    var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      iso.run(startScheduler, Env().toJson());
    } finally {
      waitForEx(iso.close());
    }
  }
}

/// Isolate callback must be a top level function.
void startScheduler(String environment) {
  try {
    print(orange('RenewManager is starting'));
    Env().fromJson(environment);
    Settings().setVerbose(enabled: Environment().debug);
    // ngix is running we now need to start the certbot renew scheduler.
    Certbot().scheduleRenews();

    /// keep the isolate running forever.
    while (true) {
      sleep(10);
    }
  } catch (e, st) {
    printerr(red('RenewalManager has shutdown due to an unexpected error: ${e.runtimeType}'));
    printerr(e.toString());
    printerr(st.toString());
    Email.sendError(subject: e.toString(), body: st.toString());
  } finally {
    print(orange('RenewManager has shutting down.'));
  }
}
