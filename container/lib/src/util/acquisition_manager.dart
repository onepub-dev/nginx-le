/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:isolates/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/////////////////////////////////////////////
/// Acquire thread
/////////////////////////////////////////////
///
class AcquisitionManager {
  factory AcquisitionManager() => _self ??= AcquisitionManager._internal();

  AcquisitionManager._internal();

  static AcquisitionManager? _self;

  Future<void> start() async {
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

    // ignore: discarded_futures
    final iso = await IsolateRunner.spawn();

    try {
      unawaited(iso.run(_acquireThread, Env().toJson()));
    } finally {
      /// let the isolate run in the background so we can return immediately.
      // ignore: discarded_futures
      await iso.close();
    }
  }

  void enterAcquisitionMode({
    required bool reload,
    bool show = false,
  }) {
    /// symlink in the http configs which only permit certbot access
    final _created = createContentSymlink(acquisitionMode: true);

    if (!inAcquisitionMode && show) {
      print(red('*') * 120);
      print(red('No valid certificates Found!!'));
      print(red("* Nginx-LE is running in 'Certificate Acquisition' mode. "
          'It will only respond to CertBot validation requests.'));
      print(red('*') * 120);
    }

    /// only reload if things changed
    if (reload && _created) {
      print('Reloading nginx as we entered acquisition mode.');
      Nginx.reload();
    }
  }

  void leaveAcquistionMode({
    required bool reload,
    bool show = false,
  }) {
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
  /// Checks if we need to acquire a certificate and if
  /// so acquire it.
  /// If we end with valid and deployed certificate
  /// we leave acquisition mode.
  Future<void> acquireIfRequired({bool reload = true}) async {
    final hostname = Environment().hostname;
    final domain = Environment().domain;
    final wildcard = Environment().domainWildcard;
    final production = Environment().production;

    try {
      if (Certbot().isDeployed()) {
        leaveAcquistionMode(reload: reload);
      } else {
        /// Places the server into acquire mode if certificates
        /// are not deployed.
        enterAcquisitionMode(reload: reload);

        if (Certbot().hasValidCertificate()) {
          if (Certbot().deployCertificate()) {
            leaveAcquistionMode(reload: reload);
            print(orange('AcquisitionManager completed successfully.'));
          } else {
            print(orange('AcquisitionManager failed to deploy certificates. '
                'Will remain in acquistion mode.'));
          }
        } else {
          ///
          if (Certbot().isBlocked) {
            print(red('''
Acquisition is blocked due to a prior error. 
Nginx-le will try again at ${Certbot().blockedUntil}. 
Alternately resolve the error and then run nginx-le acquire 
  or 
delete /etc/letsencrypt/block_acquisitions.flag from within the container.'''));
          } else {
            Settings().setVerbose(enabled: Environment().debug);
            final authProvider =
                AuthProviders().getByName(Environment().authProvider!);
            if (authProvider == null) {
              throw CertbotException('No valid auth provider was found for '
                  '${Environment().authProvider}. '
                  'Check ${Environment.authProviderKey}');
            }

            /// Acquire a new certificate
            print(green(
                'Acquiring a new certificate using ${authProvider.name}.'));
            authProvider.acquire();

            /// find the cert we just acquired.
            final cert = Certificate.find(
                hostname: hostname,
                domain: domain,
                wildcard: wildcard,
                production: production);

            var success = false;
            if (cert != null) {
              print('${orange('Acquired certificate:')}\n $cert');

              if (Certbot().deployCertificate()) {
                leaveAcquistionMode(reload: reload);
                success = true;
              }
            }

            if (success) {
              print(orange(
                  'AcquisitionManager successfully deployed the certficate.'));
            } else {
              print(
                  orange('AcquisitionManager failed to acquire a certificate. '
                      'Will remain in acquistion mode.'));
            }
          }
        }
      }
    } on CertbotException catch (e, st) {
      Certbot().blockAcquisitions();
      print('');
      print('*' * 80);
      print(red('Acquisition has failed. '
          'Retries will be blocked for fifteen minutes.'));
      print('*' * 80);
      print('');

      print(red(e.message));
      if (e.details != null) {
        print('${'*' * 30} Cerbot Error details begin: ${'*' * 30}');
        print(e.details);
        print('${'*' * 30} Cerbot Error details end: ${'*' * 30}');
      }
      await Email.sendError(subject: e.message, body: '${e.details}\n $st');
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      Certbot().blockAcquisitions();
      print(red('Acquisition has failed due to an unexpected '
          'error: ${e.runtimeType}'));
      print(e);
      print(st);
      await Email.sendError(subject: e.toString(), body: st.toString());
    }
  }

  /// returns true if we are currently in acquisition mode or
  /// [CertbotPaths().WWW_PATH_LIVE] doesn't exists which means
  /// we haven't been configured.
  bool get inAcquisitionMode =>
      exists(CertbotPaths().wwwPathLive, followLinks: false) &&
      exists(CertbotPaths().wwwPathLive) &&
      resolveSymLink(CertbotPaths().wwwPathLive) ==
          CertbotPaths().wwwPathToAcquire;
}

/// Global function required for isolate.
Future<void> _acquireThread(String environment) async {
  Env().fromJson(environment);

  if (!Environment().autoAcquire) {
    print("AUTO_ACQUIRE=false please use 'nginx-le acquire' "
        'to acquire a certificate');
  } else {
    // we give nginx a little time to start so we don't deploy and
    // attempt a reload before its running.
    // We should really use a flag to ensure that nginx has started.
    sleep(10);

    /// start the acquisition loop.
    // ignore: literal_only_boolean_expressions
    do {
      await AcquisitionManager().acquireIfRequired();

      Settings().setVerbose(enabled: false);
      sleep(5, interval: Interval.minutes);
      Settings().setVerbose(enabled: Environment().debug);
    } while (true);
  }
}
