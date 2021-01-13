import 'package:dcli/dcli.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/////////////////////////////////////////////
/// Acquire thread
/////////////////////////////////////////////
///
class AcquisitionManager {
  void start() {
    print(orange('AcquisitionManager is starting'));

    /// If we have a cert make certain its deployed
    /// We need to do this immedately as
    /// when the service starts nginx, the symlinks
    /// need to be in place.
    /// At this point nginx isn't running so don't try to reload it.
    Certbot().deployCertificates(reload: false);

    var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      iso.run(_acquireThread, Env().toJson());
    } finally {
      waitForEx(iso.close());
    }
  }
}

void _acquireThread(String environment) {
  Env().fromJson(environment);

  if (!Environment().autoAcquire) {
    print(
        "AUTO_ACQUIRE=false please use 'nginx-le acquire' to acquire a certificate");
  } else {
    // we give nginx a litte time to start so we don't deploy and
    // attempt a reload before its running.
    // We should really use a flag to ensure that nginx has started.
    sleep(10);

    /// start the acquisition loop.
    do {
      acquistionCheck();
      sleep(5, interval: Interval.minutes);
    } while (true);
  }
}

void acquistionCheck() {
  try {
    if (Certbot().hasValidCertificate()) {
      /// Places the server into acquire mode if certificates are not valid.
      ///
      if (!Certbot().isDeployed()) {
        Certbot().deployCertificates();
      }
    } else {
      if (Certbot().isBlocked) {
        print(red(
            'Acquisition is blocked due to a prior error. Nginx-le will try again at ${Certbot().blockedUntil}. Alternately resolve the error and then run nginx-le acquire.'));
      } else {
        Settings().setVerbose(enabled: Environment().debug);
        var authProvider =
            AuthProviders().getByName(Environment().authProvider);
        authProvider.acquire();
        Certbot().deployCertificates();

        print(orange('AcquisitionManager completed successfully.'));
      }
    }
  } on CertbotException catch (e, st) {
    Certbot().blockAcquisitions();
    print(red(
        'Acquisition has failed. Retries will be blocked for fifteen minutes.'));

    print(red(e.message));
    print('Cerbot Error details begin: ${'*' * 20}');
    print(e.details);
    print('Cerbot Error details end: ${'*' * 20}');
    print(st.toString());
    Email.sendError(
        subject: e.message, body: '${e.details}\n ${st.toString()}');
  } catch (e, st) {
    Certbot().blockAcquisitions();
    print(red(
        'Acquisition has failed due to an unexpected error: ${e.runtimeType}'));
    print(e.toString());
    print(st.toString());
    Email.sendError(subject: e.toString(), body: st.toString());
  }
}
