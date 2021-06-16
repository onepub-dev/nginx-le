import 'package:dcli/dcli.dart';
import 'package:isolates/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/////////////////////////////////////////////
/// Acquire thread
/////////////////////////////////////////////
///
class AcquisitionManager {
  static AcquisitionManager? _self;

  factory AcquisitionManager() => _self ??= AcquisitionManager._internal();

  AcquisitionManager._internal();

  void start() {
    print(orange('AcquisitionManager is starting'));

    if (Certbot().hasValidCertificate()) {
      if (Certbot().isDeployed()) {
        leaveAcquistionMode(show: true, reload: false);
      } else {
        /// We have a cert so make certain its deployed.
        /// We need to do this immedately as
        /// when the service starts nginx, the symlinks
        /// need to be in place.
        /// At this point nginx isn't running so don't try to reload it.
        if (Certbot().deployCertificate()) {
          leaveAcquistionMode(show: true, reload: false);
        } else {
          // deploy failed which should never happen here
          // as we started by checking the certs were valid.
          enterAcquisitionMode(show: true, reload: false);
        }
      }
    } else {
      enterAcquisitionMode(show: true, reload: false);
    }

    var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

    try {
      iso.run(_acquireThread, Env().toJson());
    } finally {
      /// let the isolate run in the background so we can return immediately.
      waitForEx(iso.close());
    }
  }

  void enterAcquisitionMode({bool show = false, required bool reload}) {
    /// symlink in the http configs which only permit certbot access
    final _created = createContentSymlink(acquisitionMode: true);

    if (!inAcquisitionMode && show) {
      print(red('*') * 120);
      print(red('No valid certificates Found!!'));
      print(red(
          "* Nginx-LE is running in 'Certificate Acquisition' mode. It will only respond to CertBot validation requests."));
      print(red('*') * 120);
    }

    /// only reload if things changed
    if (reload && _created) {
      print('Reloading nginx as we entered acquisition mode.');
      Nginx.reload();
    }
  }

  void leaveAcquistionMode({bool show = false, required bool reload}) {
    final _created = createContentSymlink(acquisitionMode: false);

    if (inAcquisitionMode) {
      if (show) {
        print(green('*') * 120);
        print(green('* Nginx-LE is running with an active Certificate.'));
        print(green('*') * 120);
      }
    } else if (show) {
      print(green('* Nginx-LE is running with an active Certificate.'));
    }

    if (reload && _created) {
      print('Reloading nginx as we left acquisition mode.');
      Nginx.reload();
    }
  }

  /// Main entry point for the isolate.
  /// The [reload] flag controls whether we reload nginx after deploying
  /// certificates. This is true by default and only set to false for unit
  /// testing.
  void acquistionCheck({bool reload = true}) {
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var wildcard = Environment().domainWildcard;
    var production = Environment().production;

    try {
      if (Certbot().isDeployed()) {
        leaveAcquistionMode(reload: reload);
      } else {
        /// Places the server into acquire mode if certificates are not deployed.
        enterAcquisitionMode(reload: reload);

        if (Certbot().hasValidCertificate()) {
          if (Certbot().deployCertificate()) {
            leaveAcquistionMode(reload: reload);
            print(orange('AcquisitionManager completed successfully.'));
          } else {
            print(orange(
                'AcquisitionManager failed to deploy certificates. Will remain in acquistion mode.'));
          }
        } else {
          ///
          if (Certbot().isBlocked) {
            print(red(
                'Acquisition is blocked due to a prior error. Nginx-le will try again at ${Certbot().blockedUntil}. Alternately resolve the error and then run nginx-le acquire or delete /etc/letsencrypt/block_acquistion.flag.'));
          } else {
            Settings().setVerbose(enabled: Environment().debug);
            var authProvider =
                AuthProviders().getByName(Environment().authProvider!);
            if (authProvider == null) {
              throw CertbotException(
                  'No valid auth provider was found for ${Environment().authProvider}. Check ${Environment().authProviderKey}');
            }

            /// Acquire a new certificate
            print(green(
                'Acquiring a new certificate using ${authProvider.name}.'));
            authProvider.acquire();

            /// find the cert we just acquired.
            var cert = Certificate.find(
                hostname: hostname,
                domain: domain,
                wildcard: wildcard,
                production: production);

            print('${orange('Acquired certificate:')}\n $cert');

            if (Certbot().deployCertificate()) {
              leaveAcquistionMode(reload: reload);
              print(orange(
                  'AcquisitionManager successfully deployed the certficate.'));
            } else {
              print(orange(
                  'AcquisitionManager failed to acquire a certificate. Will remain in acquistion mode.'));
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
  bool get inAcquisitionMode {
    return exists(CertbotPaths().WWW_PATH_LIVE, followLinks: false) &&
        exists(CertbotPaths().WWW_PATH_LIVE, followLinks: true) &&
        resolveSymLink(CertbotPaths().WWW_PATH_LIVE) ==
            CertbotPaths().WWW_PATH_ACQUIRE;
  }
}

/// Global function required for isolate.
void _acquireThread(String environment) {
  Env().fromJson(environment);

  if (!Environment().autoAcquire) {
    print(
        "AUTO_ACQUIRE=false please use 'nginx-le acquire' to acquire a certificate");
  } else {
    // we give nginx a little time to start so we don't deploy and
    // attempt a reload before its running.
    // We should really use a flag to ensure that nginx has started.
    sleep(10);

    /// start the acquisition loop.
    do {
      AcquisitionManager().acquistionCheck();

      Settings().setVerbose(enabled: false);
      sleep(5, interval: Interval.minutes);
      Settings().setVerbose(enabled: Environment().debug);
    } while (true);
  }
}
