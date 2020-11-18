import 'package:dcli/dcli.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/////////////////////////////////////////////
/// Acquire thread
/////////////////////////////////////////////
///
class AcquisitionManager {
  void start() {
    print('Starting the certificate acquire thread.');

    var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      iso.run(_acquireThread, Env().toJson());
    } finally {
      waitForEx(iso.close());
    }
  }
}

void _acquireThread(String environment) {
  try {
    print(orange('AcquisitionManager is starting'));
    Env().fromJson(environment);

    Settings().setVerbose(enabled: Environment().debug);
    var authProvider = AuthProviders().getByName(Environment().authProvider);
    authProvider.acquire();

    Certbot().deployCertificates(
        hostname: Environment().hostname,
        domain: Environment().domain,
        reload:
            true, // don't try to reload nginx as it won't be running as yet.
        wildcard: Environment().domainWildcard,
        autoAcquireMode: Environment().autoAcquire);
    print(orange('AcquisitionManager completed successfully.'));
  } on CertbotException catch (e, st) {
    Certbot().blockAcquisitions();
    printerr(e.message);
    printerr('Cerbot Error details begin: ${'*' * 20}');
    printerr(e.details);
    printerr('Cerbot Error details end: ${'*' * 20}');
    printerr(st.toString());
    Email.sendError(
        subject: e.message, body: '${e.details}\n ${st.toString()}');
  } catch (e, st) {
    Certbot().blockAcquisitions();
    printerr(red(
        'AcquisitionManager has shutdown due to an unexpected error: ${e.runtimeType}'));
    printerr(e.toString());
    printerr(st.toString());
    Email.sendError(subject: e.toString(), body: st.toString());
  } finally {
    print(orange('AcquisitionManager has shut down.'));
  }
}
