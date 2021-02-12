import 'package:cron/cron.dart';
import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_shared/src/util/email.dart';
import 'package:path/path.dart';

import '../../nginx_le_shared.dart';

class Certbot {
  static Certbot _self;

  bool _sendToStdout = false;
  factory Certbot() => _self ??= Certbot._internal();

  /// The certbot log file
  String get logfile =>
      join(CertbotPaths().letsEncryptLogPath, CertbotPaths().LOG_FILE_NAME);

  Certbot._internal() {
    Settings().verbose('Logging to $logfile');

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

  /// Check that we have valid certificates and deploys them to nginx.
  ///
  /// If we have no certificates then we force nginx into acquire mode.
  ///
  /// The certificates are stored in a persistant volume called 'certificates'
  /// and we need to copy them into /etc/nginx/certs on each start
  /// so that nginx has access to them.
  ///
  /// returns true if it deployed a valid certificate
  bool deployCertificates({
    bool reload = true,
  }) {
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var wildcard = Environment().domainWildcard;
    var hasValidCerts = Certbot().hasValidCertificate();

    var deployed = false;

    if (hasValidCerts) {
      print(orange('Deploying certificates.'));
      _deploy(CertbotPaths()
          .certificatePathRoot(hostname, domain, wildcard: wildcard));
      deployed = true;
    }

    if (reload) {
      _reloadNginx();
    }
    if (deployed) {
      print('Deploy complete.');
    }

    return deployed;
  }

  /// true if we have a valid certificate for the given arguments
  /// and it has not expired.
  bool hasValidCertificate() {
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var wildcard = Environment().domainWildcard;
    var foundValidCertificate = false;

    for (var certificate in certificates()) {
      if (certificate.wasIssuedFor(
          hostname: hostname, domain: domain, wildcard: wildcard)) {
        foundValidCertificate = true;
        break;
      }
    }

    return foundValidCertificate;
  }

  /// revokes any certificates that are not for the current
  /// fqdn and wildcard type.
  void revokeInvalidCertificates(
      {@required String hostname,
      @required String domain,
      @required bool wildcard,
      @required bool production}) {
    /// First try non-expired certificates
    for (var certificate in certificates()) {
      if (!certificate.wasIssuedFor(
          hostname: hostname, domain: domain, wildcard: wildcard)) {
        print(
            'Found certificate that does not match the required settings. host: $hostname domain: $domain wildard: $wildcard. Revoking certificate.');

        certificate.revoke();
      }

      /// revoke any really old certificates
      if (certificate.hasExpired(
          asAt: DateTime.now().subtract(Duration(days: 90)))) {
        print(
            'Found certificate that expired more than 90 days ago. host: $hostname domain: $domain wildard: $wildcard. Revoking certificate.');

        certificate.revoke();
      }
    }
  }

  /// true if we have a valid certificate and it has been deployed
  bool isDeployed() {
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var wildcard = Environment().domainWildcard;
    var deployed = false;

    var fullchain =
        join(CertbotPaths().nginxCertPath, CertbotPaths().FULLCHAIN_FILE);
    var private =
        join(CertbotPaths().nginxCertPath, CertbotPaths().PRIVATE_KEY_FILE);
    if (exists(fullchain) &&
        exists(private) &&
        wasIssuedTo(hostname: hostname, domain: domain, wildcard: wildcard)) {
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
  bool wasIssuedTo(
      {@required String hostname,
      @required String domain,
      @required bool wildcard}) {
    /// First try non-expired certificates
    for (var certificate in certificates()) {
      if (certificate.hasExpired()) continue;

      if (certificate.wasIssuedFor(
          hostname: hostname, domain: domain, wildcard: wildcard)) {
        return true;
      } else {
        print(red(
            'Found Certificate that was not issued to expected domain: expected $hostname.$domain, wildcard: $wildcard found ${certificate.fqdn}, wildcard: ${certificate.wildcard}'));
        return false;
      }
    }

    /// now consider expired certificates
    for (var certificate in certificates()) {
      if (certificate.wasIssuedFor(
          hostname: hostname, domain: domain, wildcard: wildcard)) {
        return true;
      } else {
        print(red(
            'Found expired certificate that was not issued to expected domain: expected $hostname.$domain, wildcard: $wildcard found ${certificate.fqdn}, wildcard: ${certificate.wildcard}'));

        return false;
      }
    }
    return false;
  }

  void deployCertificatesDirect(String certificateRootPath,
      {bool revoking = false, bool reload = true}) {
    if (exists(CertbotPaths().WWW_PATH_LIVE, followLinks: false)) {
      deleteSymlink(CertbotPaths().WWW_PATH_LIVE);
    }

    if (!revoking) {
      print(orange('Deploying certificates'));

      /// symlink the user's operational content
      symlink(CertbotPaths().WWW_PATH_OPERATING, CertbotPaths().WWW_PATH_LIVE);
      _deploy(certificateRootPath);
      print(green('*') * 120);
      print(green('* Nginx-LE is running with an active Certificate.'));
      print(green('*') * 120);
    } else {
      print(red('*') * 120);
      print(red('Certificates Revoked.'));
      print(red(
          "* Nginx-LE is running in 'Certificate Acquisition' mode. It will only respond to CertBot validation requests."));
      print(red('*') * 120);

      /// symlink in the http configs which only permit certbot access

      symlink(CertbotPaths().WWW_PATH_ACQUIRE, CertbotPaths().WWW_PATH_LIVE);
    }

    if (reload) _reloadNginx();
  }

  /// copy the certificate files from the given root directory.
  void _deploy(String certificateRootPath) {
    /// we need to leave the original files in place as they form part
    /// of the letsencrypt archive
    copy(
        CertbotPaths().fullChainPath(certificateRootPath), '/tmp/fullchain.pem',
        overwrite: true);
    copy(CertbotPaths().privateKeyPath(certificateRootPath), '/tmp/privkey.pem',
        overwrite: true);

    /// but we need to move them in place using move so that
    /// the replace is essentially atomic so that nginx doesn't see partially
    /// created certificates.
    move('/tmp/fullchain.pem',
        join(CertbotPaths().nginxCertPath, CertbotPaths().FULLCHAIN_FILE),
        overwrite: true);
    move('/tmp/privkey.pem',
        join(CertbotPaths().nginxCertPath, CertbotPaths().PRIVATE_KEY_FILE),
        overwrite: true);
  }

  /// Revokes a certbot certificate.
  ///
  /// You can use this if your certificate has been compromised.
  /// It is also used for testing.
  ///
  /// Before you revoke the certificate you must to place the system into
  /// acquistion mode otherwise nginx may shutdown.
  void revoke(
      {@required String hostname,
      @required String domain,
      @required bool production,
      @required bool wildcard,
      @required String emailaddress}) {
    var workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    var logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    var configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    var certFilePath = join(
        CertbotPaths()
            .certificatePathRoot(hostname, domain, wildcard: wildcard),
        CertbotPaths().CERTIFICATE_FILE);
    print('Revoking certificate at: $certFilePath');
    // print('isDirectory: ${isDirectory(certFilePath)}');
    // print('isFile: ${isFile(certFilePath)}');
    // print('isLink: ${isLink(certFilePath)}');

    NamedLock(name: 'certbot').withLock(() {
      var cmd = 'certbot revoke'
          ' --cert-path $certFilePath'
          ' --non-interactive '
          ' -m $emailaddress  '
          ' --agree-tos '
          ' --work-dir=$workDir '
          ' --config-dir=$configDir '
          ' --logs-dir=$logDir '
          ' --delete-after-revoke';

      if (!production) cmd += ' --staging ';

      var progress = Progress(
        (line) => print(line),
        stderr: (line) => print(line),
      );
      cmd.start(
        runInShell: true,
        nothrow: true,
        progress: progress,
      );

      if (progress.exitCode != 0) {
        throw CertbotException(
            'Revocation of certificate: $hostname.$domain failed. See logs for details');
      }
    });
  }

  /// used by revoke to delete certificates after they have been revoked
  /// If we don't do this then the revoked certificates will still be renewed.
  // ignore: unused_element
  void _delete(String hostname, String domain,
      {@required bool wildcard, @required String emailaddress}) {
    var workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    var logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    var configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    NamedLock(name: 'certbot').withLock(() {
      var cmd = 'certbot delete'
          ' --cert-name ${wildcard ? domain : '$hostname.$domain'}'
          ' --non-interactive '
          ' -m $emailaddress  '
          ' --agree-tos '
          ' --work-dir=$workDir '
          ' --config-dir=$configDir '
          ' --logs-dir=$logDir ';

      cmd.start(
          runInShell: true,
          nothrow: true,
          progress: Progress((line) {
            if (!line.startsWith('- - - -') &&
                !line.startsWith('Saving debug ')) {
              print(line);
            }
          }, stderr: (line) => print(line)));
    });
  }

  /// Checks if the certificate for the given hostname.domain
  /// has expired
  bool hasExpired(String hostname, String domain) {
    var certificatelist = certificates();
    Settings().verbose(
        red('HasExpired evaluating ${certificatelist.length} certificates'));
    if (certificatelist.isEmpty) {
      return true;
    }

    var certificate = certificatelist[0];
    Settings().verbose('testing expiry for ${certificate}');
    return certificate.hasExpired();
  }

  /// Obtain the list of active certificates
  List<Certificate> certificates() {
    return Certificate.load();
  }

  void scheduleRenews() {
    var cron = Cron();

    /// run cron at 1 am  everyday
    cron.schedule(Schedule.parse('0 1 * * *'), () async {
      try {
        renew();
      } on CertbotException catch (e, st) {
        print(e.message);
        print(e.details);
        print(st.toString());
        Email.sendError(
            subject: e.message, body: '${e.details}\n ${st.toString()}');
      } catch (e, st) {
        /// we don't rethrow as we don't want to shutdown the scheduler.
        /// as this may be a temporary error.
        print(e.toString());
        print(st.toString());

        Email.sendError(subject: e.toString(), body: st.toString());
      }
    });
  }

  void renew({bool force = false}) {
    print(
        'Attempting renew using deploy-hook at: ${Environment().certbotDeployHookPath}');

    NamedLock(name: 'certbot').withLock(() {
      var certbot = 'certbot renew '
          ' --agree-tos '
          ' --deploy-hook=${Environment().certbotDeployHookPath}'
          ' --work-dir=${CertbotPaths().letsEncryptWorkPath}'
          ' --config-dir=${CertbotPaths().letsEncryptConfigPath}'
          ' --logs-dir=${CertbotPaths().letsEncryptLogPath}';

      if (force == true) {
        certbot += ' --force-renewal';
      }

      var lines = <String>[];
      var progress = Progress((line) {
        print(line);
        lines.add(line);
      }, stderr: (line) {
        print(line);
        lines.add(line);
      });

      certbot.start(runInShell: true, nothrow: true, progress: progress);

      if (progress.exitCode != 0) {
        var system = 'hostname'.firstLine;

        throw CertbotException(
            'certbot failed renewing a certificate for ${Environment().fqdn} on $system',
            details: lines.join('\n'));
      }
    });
  }

  void log(String message) {
    if (_sendToStdout) {
      print(message);
    } else {
      logfile.append(message);
    }
  }

  void logError(String message) {
    logfile.append('*' * 80);
    logfile.append('*');
    logfile.append('*    ERROR: $message');
    logfile.append('*');
    logfile.append('*' * 80);
  }

  void _reloadNginx() {
    if (exists('/var/run/nginx.pid')) {
      /// force nginx to reload its config.
      'nginx -s reload'.run;
    } else {
      Settings().verbose('Nginx reload ignored as nginx is not running');
    }
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
    for (var cert in Certbot().certificates()) {
      print('Revoking ${cert.fqdn}');
      var hostname = cert.fqdn.split('.')[0];
      var domain = cert.fqdn.split('.').sublist(1).join('.');
      Certbot().revoke(
          hostname: hostname,
          domain: domain,
          production: cert.production,
          wildcard: cert.wildcard,
          emailaddress: Environment().emailaddress);
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

  bool get isBlocked {
    return _hasValidBlockFlag && !Environment().certbotIgnoreBlock;
  }

  /// returns true if the block flag file exists and it is no more than 15 minutes old
  /// Essentially we allow an acquisition to retry every 15 minutes on the assumption
  /// that it was a temporary failure and the user has had time to fix it.
  bool get _hasValidBlockFlag =>
      _blockFlagExists && blockedUntil.isAfter(DateTime.now());

  /// If acquisitions are blocked returns the time at which it will be unblocked.
  /// If acquistions are not blocked returns the curren time.
  DateTime get blockedUntil => _blockFlagExists
      ? stat(pathToBlockFlag).changed.add(Duration(minutes: 15))
      : DateTime.now();

  bool get _blockFlagExists => exists(pathToBlockFlag);

  void clearBlockFlag() {
    if (exists(pathToBlockFlag)) {
      delete(pathToBlockFlag);
    }
  }

  String get pathToBlockFlag =>
      join(Environment().certbotRootPath, 'block_acquisitions.flag');
}

class CertbotException implements Exception {
  String message;
  String details;
  CertbotException(this.message, {this.details});

  @override
  String toString() => message;
}
