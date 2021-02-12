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

    if (Certbot().hasValidCertificate()) {
      if (Certbot().isDeployed()) {
        AcquisitionManager.leaveAcquistionMode(show: true);
      } else {
        /// We have a cert so make certain its deployed.
        /// We need to do this immedately as
        /// when the service starts nginx, the symlinks
        /// need to be in place.
        /// At this point nginx isn't running so don't try to reload it.
        if (Certbot().deployCertificates(reload: false)) {
          AcquisitionManager.leaveAcquistionMode(show: true);
        } else {
          // deploy failed which should never happen here
          // as we started by checking the certs were valid.
          AcquisitionManager.enterAcquisitionMode(show: true);
        }
      }
    } else {
      AcquisitionManager.enterAcquisitionMode(show: true);
    }

    var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      iso.run(_acquireThread, Env().toJson());
    } finally {
      /// let the isolate run in the background so we can return immediately.
      waitForEx(iso.close());
    }
  }

  static void enterAcquisitionMode({bool show = false}) {
    /// symlink in the http configs which only permit certbot access
    _createSymlink(CertbotPaths().WWW_PATH_ACQUIRE);

    if (!inAcquisitionMode || show) {
      print(red('*') * 120);
      print(red('No valid certificates Found!!'));
      print(red(
          "* Nginx-LE is running in 'Certificate Acquisition' mode. It will only respond to CertBot validation requests."));
      print(red('*') * 120);
    }
  }

  static void leaveAcquistionMode({bool show = false}) {
    _createSymlink(CertbotPaths().WWW_PATH_OPERATING);

    if (inAcquisitionMode || show) {
      print(green('*') * 120);
      print(green('* Nginx-LE is running with an active Certificate.'));
      print(green('*') * 120);
    } else if (show) {
      print(green('* Nginx-LE is running with an active Certificate.'));
    }
  }

  /// Main entry point for the isolate.
  /// The [reload] flag controls whether we reload nginx after deploying
  /// certificates. This is true by default and only set to false for unit
  /// testing.
  static void acquistionCheck({bool reload = true}) {
    try {
      if (!Certbot().isDeployed()) {
        /// Places the server into acquire mode if certificates are not deployed.
        enterAcquisitionMode();

        if (Certbot().hasValidCertificate()) {
          if (Certbot().deployCertificates(reload: reload)) {
            leaveAcquistionMode();
            print(orange('AcquisitionManager completed successfully.'));
          } else {
            print(orange(
                'AcquisitionManager failed to deploy certificates. Will remain in acquistion mode.'));
          }
        } else {
          ///
          if (Certbot().isBlocked) {
            print(red(
                'Acquisition is blocked due to a prior error. Nginx-le will try again at ${Certbot().blockedUntil}. Alternately resolve the error and then run nginx-le acquire.'));
          } else {
            Settings().setVerbose(enabled: Environment().debug);
            var authProvider =
                AuthProviders().getByName(Environment().authProvider);

            /// Acquire a new certificate
            print(green('Acquiring a new certificate.'));
            authProvider.acquire();

            if (Certbot().deployCertificates(reload: reload)) {
              leaveAcquistionMode();
              print(orange(
                  'AcquisitionManager successfully deployed certficates.'));
            } else {
              print(orange(
                  'AcquisitionManager failed to acquire certificates. Will remain in acquistion mode.'));
            }
          }
        }
      }
    } on CertbotException catch (e, st) {
      Certbot().blockAcquisitions();
      print('');
      print('*' * 80);
      print(red(
          'Acquisition has failed. Retries will be blocked for fifteen minutes.'));
      print('*' * 80);
      print('');

      print(red(e.message));
      print('${'*' * 30} Cerbot Error details begin: ${'*' * 30}');
      print(e.details);
      print('${'*' * 30} Cerbot Error details end: ${'*' * 30}');
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

  /// returns true if we are currently in acquisition mode or
  /// [CertbotPaths().WWW_PATH_LIVE] doesn't exists which means we haven't been configured.
  static bool get inAcquisitionMode {
    return exists(CertbotPaths().WWW_PATH_LIVE, followLinks: false) &&
        exists(CertbotPaths().WWW_PATH_LIVE, followLinks: true) &&
        resolveSymLink(CertbotPaths().WWW_PATH_LIVE) ==
            CertbotPaths().WWW_PATH_ACQUIRE;
  }

  static void _createSymlink(String targetPath) {
    var validTarget = false;
    var existing = false;
    // we are about to recreate the symlink to the appropriate path
    if (exists(CertbotPaths().WWW_PATH_LIVE, followLinks: false)) {
      existing = true;
      if (exists(CertbotPaths().WWW_PATH_LIVE)) {
        validTarget = true;
      }
    }

    if (validTarget) {
      if (resolveSymLink(CertbotPaths().WWW_PATH_LIVE) != targetPath) {
        deleteSymlink(CertbotPaths().WWW_PATH_LIVE);
        symlink(targetPath, CertbotPaths().WWW_PATH_LIVE);
      }
      // else the symlink already points at the target.
    } else {
      /// the current target is invalid so recreate the link.
      if (existing) deleteSymlink(CertbotPaths().WWW_PATH_LIVE);
      symlink(targetPath, CertbotPaths().WWW_PATH_LIVE);
    }
  }
}

/// Global function required for isolate.
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
      AcquisitionManager.acquistionCheck();

      Settings().setVerbose(enabled: false);
      sleep(5, interval: Interval.minutes);
      Settings().setVerbose(enabled: Environment().debug);
    } while (true);
  }
}
