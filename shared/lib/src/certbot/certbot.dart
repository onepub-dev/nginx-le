/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:math';

import 'package:cron/cron.dart';
import 'package:dcli/dcli.dart' hide delete;
import 'package:dcli/dcli.dart' as dcli;
import 'package:path/path.dart';

import '../../nginx_le_shared.dart';

class Certbot {
  factory Certbot() => _self ??= Certbot._internal();

  Certbot._internal() {
    verbose(() => 'Logging to $logfile');

    if (!exists(CertbotPaths().letsEncryptLogPath)) {
      createDir(CertbotPaths().letsEncryptLogPath, recursive: true);
    }

    if (!exists(CertbotPaths().letsEncryptWorkPath)) {
      createDir(CertbotPaths().letsEncryptWorkPath, recursive: true);
    }

    if (!exists(CertbotPaths().letsEncryptConfigPath)) {
      createDir(CertbotPaths().letsEncryptConfigPath, recursive: true);
    }
  }

  static Certbot? _self;

  /// The install creates a virtual python environment
  /// for certbot in /opt/certbot so we must run
  /// all commands from that directory.
  static const pathTo = '/opt/certbot/bin/certbot';

  bool _sendToStdout = false;

  /// The certbot log file
  String get logfile =>
      join(CertbotPaths().letsEncryptLogPath, CertbotPaths().logFilename);

  /// Check that we have valid certificate and deploy it to nginx.
  ///
  ///
  /// Certificates are stored in a persistant volume called 'certificates'
  /// and we need to copy the active certificate into /etc/nginx/certs on each start
  /// so that nginx has access to them.
  ///
  /// returns true if we deployed a valid certificate
  bool deployCertificate() {
    final hostname = Environment().hostname;
    final domain = Environment().domain;
    final wildcard = Environment().domainWildcard;

    print('Checking for valid certificate');
    final hasValidCerts = Certbot().hasValidCertificate();

    var deployed = false;

    if (hasValidCerts) {
      print(orange('Deploying certificate.'));
      _deploy(CertbotPaths()
          .certificatePathRoot(hostname, domain, wildcard: wildcard));
      deployed = true;
    } else {
      print('No valid certificates found during deploy');
    }

    return deployed;
  }

  /// true if we have a valid certificate for the given arguments
  /// and it has not expired.
  bool hasValidCertificate() {
    final hostname = Environment().hostname;
    final domain = Environment().domain;
    final wildcard = Environment().domainWildcard;
    final production = Environment().production;
    var foundValidCertificate = false;

    for (final certificate in certificates()) {
      print('Certificate found:\n $certificate');
      if (certificate!.wasIssuedFor(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          production: production)) {
        print('Found valid certificate');
        foundValidCertificate = true;
        break;
      } else {
        print('Certificate not valid');
      }
    }

    return foundValidCertificate;
  }

  /// revokes any certificates that are not for the current
  /// fqdn and wildcard type.
  int deleteInvalidCertificates(
      {required String hostname,
      required String domain,
      required bool wildcard,
      required bool production}) {
    var count = 0;

    /// First try non-expired certificates
    for (final certificate in certificates()) {
      if (!certificate!.wasIssuedFor(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          production: production)) {
        print('Found certificate that does not match the required settings. '
            'host: $hostname domain: $domain wildard: $wildcard '
            'production: $production. Deleting certificate.');

        certificate.delete();
        count++;
      }

      /// revoke any really old certificates
      if (certificate.hasExpired(
          asAt: DateTime.now().subtract(const Duration(days: 90)))) {
        print('Found certificate that expired more than 90 days ago. '
            'host: $hostname domain: $domain wildard: $wildcard '
            'production: $production. Deleting certificate.');

        certificate.delete();
        count++;
      }
    }

    return count;
  }

  /// true if we have a valid certificate and it has been deployed
  bool isDeployed() {
    final hostname = Environment().hostname;
    final domain = Environment().domain;
    final wildcard = Environment().domainWildcard;
    final production = Environment().production;
    var deployed = false;

    final fullchain =
        join(CertbotPaths().nginxCertPath, CertbotPaths().fullchainFile);
    final private =
        join(CertbotPaths().nginxCertPath, CertbotPaths().privateKeyFile);
    if (exists(fullchain) &&
        exists(private) &&
        wasIssuedFor(
            hostname: hostname,
            domain: domain,
            wildcard: wildcard,
            production: production)) {
      deployed = true;
    }
    return deployed;
  }

  /// true if if we have a certificate was issued for the given [hostname],
  /// [domain] and [wildcard] type.
  ///
  /// If there are only expired certificates then provided they were
  /// issued according to the pass args then we return true.
  ///
  /// There is a chance we could have an old bad certificate and a new
  /// good one in which case the result is random :)
  ///
  /// On start up if we find a bad certificate.
  bool wasIssuedFor(
      {required String? hostname,
      required String domain,
      required bool wildcard,
      required bool production}) {
    /// First try non-expired certificates
    for (final certificate in certificates()) {
      if (certificate!.hasExpired()) {
        continue;
      }

      if (certificate.wasIssuedFor(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          production: production)) {
        return true;
      } else {
        print(red('Ignored Certificate that was not issued to expected '
            'domain: expected ${Certificate.buildFQDN(hostname, domain)}, '
            'wildcard: $wildcard found ${certificate.fqdn}, '
            'wildcard: ${certificate.wildcard}'));
      }
    }

    /// now consider expired certificates
    for (final certificate in certificates()) {
      if (!certificate!.wasIssuedFor(
          hostname: hostname,
          domain: domain,
          wildcard: wildcard,
          production: production)) {
        continue;
      }
      if (certificate.hasExpired()) {
        print(red('Found expired certificate that was not issued to expected '
            'domain: expected ${Certificate.buildFQDN(hostname, domain)}, '
            'wildcard: $wildcard found ${certificate.fqdn}, '
            'wildcard: ${certificate.wildcard}'));

        return false;
      }
    }
    return false;
  }

  void deployCertificatesDirect(String certificateRootPath,
      {required bool reload, bool revoking = false}) {
    if (revoking) {
      print(red('*') * 120);
      print(red('Certificates Revoked.'));
      print(red("* Nginx-LE is running in 'Certificate Acquisition' mode. "
          'It will only respond to CertBot validation requests.'));
      print(red('*') * 120);

      /// symlink in the http configs which only permit certbot access
      createContentSymlink(acquisitionMode: true);
    } else {
      print(orange('Deploying certificates'));

      /// symlink the user's operational content
      createContentSymlink(acquisitionMode: false);
      _deploy(certificateRootPath);
      print(green('*') * 120);
      print(green('* Nginx-LE is running with an active Certificate.'));
      print(green('*') * 120);
    }

    if (reload) {
      print(orange('Reloading nginx so new certificates are activated'));
      Nginx.reload();
    }
  }

  /// copy the certificate files from the given root directory.
  void _deploy(String nginxCertificateRootPath) {
    // /// we need to leave the original files in place as they form part
    // /// of the letsencrypt archive
    // copy(
    //     CertbotPaths().fullChainPath(certificateRootPath), '/tmp/fullchain.pem',
    //     overwrite: true);
    // copy(CertbotPaths().privateKeyPath(certificateRootPath), '/tmp/privkey.pem',
    //     overwrite: true);

    // /// but we need to move them in place using move so that
    // /// the replace is essentially atomic so that nginx doesn't see partially
    // /// created certificates.
    // move('/tmp/fullchain.pem',
    //     join(CertbotPaths().nginxCertPath, CertbotPaths().fullchainFile),
    //     overwrite: true);
    // move('/tmp/privkey.pem',
    //     join(CertbotPaths().nginxCertPath, CertbotPaths().privateKeyFile),
    //     overwrite: true);

    /// symlink the files so nginx can see the certificate
    symlink(CertbotPaths().fullChainPath(nginxCertificateRootPath),
        join(CertbotPaths().nginxCertPath, CertbotPaths().fullchainFile));

    symlink(CertbotPaths().privateKeyPath(nginxCertificateRootPath),
        join(CertbotPaths().nginxCertPath, CertbotPaths().privateKeyFile));
  }

  /// Revokes a certbot certificate.
  ///
  /// You can use this if your certificate has been compromised.
  /// It is also used for testing.
  ///
  /// Before you revoke the certificate you must to place the system into
  /// acquistion mode otherwise nginx may shutdown.
  void revoke(
      {required String? hostname,
      required String domain,
      required bool? production,
      required bool wildcard,
      required String? emailaddress}) {
    final workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    final logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    final configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    final certFilePath = join(
        CertbotPaths()
            .certificatePathRoot(hostname, domain, wildcard: wildcard),
        CertbotPaths().certificateFile);
    print('Revoking certificate at: $certFilePath');
    // print('isDirectory: ${isDirectory(certFilePath)}');
    // print('isFile: ${isFile(certFilePath)}');
    // print('isLink: ${isLink(certFilePath)}');

    NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
        .withLock(() {
      var cmd = '${Certbot.pathTo} revoke'
          ' --cert-path $certFilePath'
          ' --non-interactive '
          ' -m $emailaddress  '
          ' --agree-tos '
          ' --work-dir=$workDir '
          ' --config-dir=$configDir '
          ' --logs-dir=$logDir '
          ' --delete-after-revoke';

      if (!production!) {
        cmd += ' --staging ';
      }

      final progress = Progress(
        print,
        stderr: print,
      );
      cmd.start(
        runInShell: true,
        nothrow: true,
        progress: progress,
      );

      if (progress.exitCode != 0) {
        throw CertbotException('Revocation of certificate: '
            '${Certificate.buildFQDN(hostname, domain)} failed. '
            'See logs for details');
      }
    });
  }

  /// used by revoke to delete certificates after they have been revoked
  /// If we don't do this then the revoked certificates will still be renewed.
  void delete({
    required bool wildcard,
    required String? emailaddress,
    required String domain,
    String? hostname,
  }) {
    final workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    final logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    final configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
        .withLock(() {
      '${Certbot.pathTo} delete'
              ' --cert-name '
              '${wildcard ? domain : Certificate.buildFQDN(hostname, domain)}'
              ' --non-interactive '
              ' -m $emailaddress  '
              ' --agree-tos '
              ' --work-dir=$workDir '
              ' --config-dir=$configDir '
              ' --logs-dir=$logDir '
          .start(
              runInShell: true,
              nothrow: true,
              progress: Progress((line) {
                if (!line.startsWith('- - - -') &&
                    !line.startsWith('Saving debug ')) {
                  print(line);
                }
              }, stderr: print));
    });
  }

  /// Checks if the certificate for the given hostname.domain
  /// has expired
  bool hasExpired(String hostname, String domain) {
    final certificatelist = certificates();
    verbose(() =>
        red('HasExpired evaluating ${certificatelist.length} certificates'));
    if (certificatelist.isEmpty) {
      return true;
    }

    final certificate = certificatelist[0]!;
    verbose(() => 'testing expiry for $certificate');
    return certificate.hasExpired();
  }

  /// Obtain the list of active certificates
  List<Certificate?> certificates() => Certificate.load();

  void scheduleRenews() {
    final cron = Cron();

    // randomize the minute to reduce the chance
    // of two systems trying to renew at the same time
    // we can be an issue for wild card certs
    // that use dns validation.
    final minute = Random().nextInt(59);

    /// run cron at 1 am  everyday
    cron.schedule(Schedule.parse('$minute 1 * * *'), () async {
      try {
        renew();
      } on CertbotException catch (e, st) {
        print(e.message);
        print(e.details);
        print(st);
        await Email.sendError(subject: e.message, body: '${e.details}\n $st');
        // ignore: avoid_catches_without_on_clauses
      } catch (e, st) {
        /// we don't rethrow as we don't want to shutdown the scheduler.
        /// as this may be a temporary error.
        print(e);
        print(st);

        await Email.sendError(subject: e.toString(), body: st.toString());
      }
    });
  }

  void renew({bool force = false}) {
    print('Attempting renew using deploy-hook at: '
        '${Environment().certbotDeployHookPath}');

    try {
      NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
          .withLock(() {
        var certbot = '${Certbot.pathTo} renew '
            ' --agree-tos '
            ' --deploy-hook=${Environment().certbotDeployHookPath}'
            ' --work-dir=${CertbotPaths().letsEncryptWorkPath}'
            ' --config-dir=${CertbotPaths().letsEncryptConfigPath}'
            ' --logs-dir=${CertbotPaths().letsEncryptLogPath}';

        if (force == true) {
          certbot += ' --force-renewal';
        }

        final lines = <String>[];
        final progress = Progress((line) {
          print(line);
          lines.add(line);
        }, stderr: (line) {
          print(line);
          lines.add(line);
        });

        certbot.start(runInShell: true, nothrow: true, progress: progress);

        if (progress.exitCode != 0) {
          final system = 'hostname'.firstLine;

          throw CertbotException(
              'certbot failed renewing a certificate for '
              '${Environment().fqdn} on $system',
              details: lines.join('\n'));
        }
      });
      // ignore: avoid_catches_without_on_clauses
    } catch (e, _) {
      print(red('Renew failed as certbot was busy. Will try again later.'));
    }
  }

  void log(String message) {
    if (_sendToStdout) {
      print(message);
    } else {
      logfile.append(message);
    }
  }

  void logError(String message) {
    logfile
      ..append('*' * 80)
      ..append('*')
      ..append('*    ERROR: $message')
      ..append('*')
      ..append('*' * 80);
  }

  String _createDir(String dir) {
    if (!exists(dir)) {
      createDir(dir, recursive: true);
    }
    return dir;
  }

  void sendToStdout() {
    _sendToStdout = true;
  }

  /// Revoke all the certificates we have.
  void revokeAll() {
    /// we revoke all the certs we have.
    /// We should only have one but if things go wrong we might have old ones
    /// lying around so this cleans things up.
    for (final cert in Certbot().certificates()) {
      print('Revoking ${cert!.fqdn}');
      cert.revoke();
    }
    print('');
  }

  /// After an unexpected error occurs we block futher acquistion attempts
  /// so we don't hit lets encrypt rate limits.
  /// Once a block is in place the user must use the cli 'acquire' command
  /// or pass in the CERTBOT_IGNORE_BLOCK=true environment variable.
  void blockAcquisitions() {
    touch(pathToBlockFlag, create: true);
  }

  bool get isBlocked => _hasValidBlockFlag && !Environment().certbotIgnoreBlock;

  /// returns true if the block flag file exists and it is no more than
  /// 15 minutes old
  /// Essentially we allow an acquisition to retry every 15 minutes on the
  ///  assumption
  /// that it was a temporary failure and the user has had time to fix it.
  bool get _hasValidBlockFlag =>
      _blockFlagExists && blockedUntil.isAfter(DateTime.now());

  /// If acquisitions are blocked returns the time at which it
  /// will be unblocked.
  /// If acquistions are not blocked returns the curren time.
  DateTime get blockedUntil => _blockFlagExists
      ? stat(pathToBlockFlag).changed.add(const Duration(minutes: 15))
      : DateTime.now();

  bool get _blockFlagExists => exists(pathToBlockFlag);

  void clearBlockFlag() {
    if (exists(pathToBlockFlag)) {
      dcli.delete(pathToBlockFlag);
    }
  }

  String get pathToBlockFlag =>
      join(Environment().certbotRootPath, 'block_acquisitions.flag');
}

class CertbotException implements Exception {
  CertbotException(this.message, {this.details});
  String message;
  String? details;

  @override
  String toString() => message;
}
