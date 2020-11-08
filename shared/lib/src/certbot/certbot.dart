import 'package:cron/cron.dart';
import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_shared/src/util/email.dart';
import 'package:path/path.dart';

import '../../nginx_le_shared.dart';
import 'certificate_paths.dart';

class Certbot {
  /// The directory where lets encrypt stores its certificates.
  /// As we need to persist certificates between container restarts
  /// the CERTBOT_ROOT_DEFAULT_PATH path is mounted to a persistent volume on start up.
  static const CERTBOT_ROOT_DEFAULT_PATH = '/etc/letsencrypt';

  /// The name of the logfile that certbot writes to.
  /// We also write our log messages to this file.
  static const LOG_FILE_NAME = 'letsencrypt.log';

  static const LIVE_WWW_PATH = '/etc/nginx/live';

  static final Certbot _self = Certbot._internal();

  bool _sendToStdout = false;
  factory Certbot() => _self;

  /// The certbot log file
  String get logfile => join(letsEncryptLogPath, LOG_FILE_NAME);
  Certbot._internal() {
    Settings().verbose('Logging to $logfile');

    if (!exists(letsEncryptLogPath)) {
      createDir(letsEncryptLogPath, recursive: true);
    }

    if (!exists(letsEncryptWorkPath)) {
      createDir(letsEncryptWorkPath, recursive: true);
    }

    if (!exists(letsEncryptConfigPath)) {
      createDir(letsEncryptConfigPath, recursive: true);
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
  void deployCertificates(
      {@required String hostname,
      @required String domain,
      bool revoking = false,
      bool reload = true,
      @required bool wildcard,
      @required bool autoAcquireMode}) {
    var hasValidCerts = false;

    envs.forEach((key, value) => print('$key=$value'));

    var certs = certificates();

    for (var cert in certs) {
      print(cert.toString());
    }

    if (!revoking) {
      var path = CertificatePaths.fullChainPath(
          CertificatePaths.certificatePathRoot(hostname, domain,
              wildcard: wildcard));
      if (exists(path)) {
        print('Found fullchain in: $path');

        if (hasExpired(hostname, domain)) {
          printerr(
              "ERROR The Certificate for $hostname.$domain has expired. Please run 'nginx-le acquire.");
        } else {
          hasValidCerts = true;
        }
      } else {
        if (!autoAcquireMode) {
          printerr(
              "No Certificates found for $hostname.$domain. You may need to run 'nginx-le acquire");
        }
      }
    }

    if (exists(LIVE_WWW_PATH, followLinks: false)) {
      deleteSymlink(LIVE_WWW_PATH);
    }

    if (hasValidCerts) {
      print(orange('Deploying certificates'));

      /// symlink the user's custom content.
      symlink('/etc/nginx/custom', LIVE_WWW_PATH);
      _deploy(CertificatePaths.certificatePathRoot(hostname, domain,
          wildcard: wildcard));
      printerr(green('*') * 120);
      printerr(green('* Nginx-LE is running with an active Certificate.'));
      printerr(green('*') * 120);
    } else {
      printerr(red('*') * 120);
      printerr(red('No certificates Found!!'));
      printerr(red(
          "* Nginx-LE is running in 'Certificate Acquisition' mode. It will only respond to CertBot validation requests."));
      printerr(red('*') * 120);

      /// symlink in the http configs which only permit certbot access
      symlink('/etc/nginx/acquire', LIVE_WWW_PATH);
    }

    if (reload) {
      _reloadNginx();
    }
  }

  void deployCertificatesDirect(String certificateRootPath,
      {bool revoking = false}) {
    if (exists(LIVE_WWW_PATH, followLinks: false)) {
      deleteSymlink(LIVE_WWW_PATH);
    }

    if (!revoking) {
      print(orange('Deploying certificates'));

      /// symlink the user's custom content.
      symlink('/etc/nginx/custom', LIVE_WWW_PATH);
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
      symlink('/etc/nginx/acquire', LIVE_WWW_PATH);
    }

    _reloadNginx();
  }

  /// copy the certificate files from the given root directory.
  void _deploy(String certificateRootPath) {
    /// we need to leave the original files in place as they form part
    /// of the letsencrypt archive
    copy(CertificatePaths.fullChainPath(certificateRootPath),
        '/tmp/fullchain.pem',
        overwrite: true);
    copy(CertificatePaths.privateKeyPath(certificateRootPath),
        '/tmp/privkey.pem',
        overwrite: true);

    /// but we need to move them in place using move so that
    /// the replace is essentially atomic so that nginx doesn't see partially
    /// created certificates.
    move('/tmp/fullchain.pem', join(nginxCertPath, 'fullchain.pem'),
        overwrite: true);
    move('/tmp/privkey.pem', join(nginxCertPath, 'privkey.pem'),
        overwrite: true);
  }

  /// Used more for testing, but essentially deletes any existing certificates
  /// and places the system into acquire mode.
  /// Could also be used to play with and remove staging certificates
  bool revoke(
      {@required String hostname,
      @required String domain,
      bool production = false,
      @required bool wildcard,
      @required String emailaddress}) {
    var workDir = _createDir(Certbot.letsEncryptWorkPath);
    var logDir = _createDir(Certbot.letsEncryptLogPath);
    var configDir = _createDir(Certbot.letsEncryptConfigPath);

    var cmd = 'certbot revoke'
        ' --cert-path ${CertificatePaths.certificatePathRoot(hostname, domain, wildcard: wildcard)}'
        ' --non-interactive '
        ' -m $emailaddress  '
        ' --agree-tos '
        ' --work-dir=$workDir '
        ' --config-dir=$configDir '
        ' --logs-dir=$logDir ';

    if (!production) cmd += ' --staging ';

    var progress = Progress(
      (line) => print(line),
      stderr: (line) => printerr(line),
    );
    cmd.start(
      runInShell: true,
      nothrow: true,
      progress: progress,
    );

    if (progress.exitCode == 0) {
      _delete(hostname, domain, emailaddress: emailaddress);
    }

    return progress.exitCode == 0;
  }

  /// used by revoke to delete certificates after they have been revoked
  /// If we don't do this then the revoked certificates will still be renewed.
  void _delete(String hostname, String domain,
      {@required String emailaddress}) {
    var workDir = _createDir(Certbot.letsEncryptWorkPath);
    var logDir = _createDir(Certbot.letsEncryptLogPath);
    var configDir = _createDir(Certbot.letsEncryptConfigPath);

    var cmd = 'certbot delete'
        ' --cert-name $hostname.$domain'
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
        }, stderr: (line) => printerr(line)));
  }

  static String get letsEncryptRootPath {
    /// allows the root to be over-ridden to make testing easier.
    return Environment().certbotRootPath;
  }

  static String get letsEncryptWorkPath {
    return join(letsEncryptRootPath, 'work');
  }

  static String get letsEncryptLogPath {
    return join(letsEncryptRootPath, 'logs');
  }

  static String get letsEncryptConfigPath {
    return join(letsEncryptRootPath, 'config');
  }

  /// Checks if the certificate for the given hostname.domain
  /// has expired
  bool hasExpired(String hostname, String domain) {
    var certificatelist = certificates();
    print(red('HasExpired found ${certificatelist.length} certificates'));
    if (certificatelist.isEmpty) {
      return true;
    }

    for (var cert in certificatelist) {
      print('${cert.toString()}');
    }

    var certificate = certificatelist[0];
    print('testing expiry for ${certificate}');
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
        printerr(e.message);
        printerr(e.details);
        printerr(st.toString());
        Email.sendError(
            subject: e.message, body: '${e.details}\n ${st.toString()}');
      } catch (e, st) {
        /// we don't rethrow as we don't want to shutdown the scheduler.
        /// as this may be a temporary error.
        printerr(e.toString());
        printerr(st.toString());

        Email.sendError(subject: e.toString(), body: st.toString());
      }
    });
  }

  void renew() {
    var certbot = 'certbot renew '
        ' --force-renewal' // for testing only!!! - TODO: REMOVE.
        ' --agree-tos '
        ' --deploy-hook=${Environment().certbotDeployHook}'
        ' --work-dir=${Certbot.letsEncryptWorkPath}'
        ' --config-dir=${Certbot.letsEncryptConfigPath}'
        ' --logs-dir=${Certbot.letsEncryptLogPath}';

    var lines = <String>[];
    var progress = Progress((line) {
      print(line);
      lines.add(line);
    }, stderr: (line) {
      printerr(line);
      lines.add(line);
    });

    certbot.start(runInShell: true, nothrow: true, progress: progress);

    if (progress.exitCode != 0) {
      var system = 'hostname'.firstLine;

      throw CertbotException(
          'certbot failed renewing a certificate for ${Environment().fqdn}on $system',
          details: lines.join('\n'));
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

  static String get nginxCertPath {
    var path = Environment().nginxCertRootPathOverwrite;

    path ??= CertificatePaths.NGINX_CERT_ROOT;
    return path;
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
  static void revokeAll() {
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
    touch(_pathToBlockFlag);
  }

  bool isBlocked() {
    return _hasValidBlockFlag && !Environment().certbotIgnoreBlock;
  }

  /// returns true if the block flag file exists and it is no more than 15 minutes old
  /// Essentially we allow an acquisition to retry every 15 minutes on the assumption
  /// that it was a temporary failure and the user has had time to fix it.
  bool get _hasValidBlockFlag {
    var valid = false;
    if (exists(_pathToBlockFlag)) {
      valid = stat(_pathToBlockFlag)
          .changed
          .add(Duration(minutes: 15))
          .isBefore(DateTime.now());
    }
    return valid;
  }

  void clearBlockFlag() {
    if (isBlocked()) {
      delete(_pathToBlockFlag);
    }
  }

  String get _pathToBlockFlag =>
      join(Environment().certbotRootPath, 'block_acquisitions.flag');
}

class CertbotException implements Exception {
  String message;
  String details;
  CertbotException(this.message, {this.details});

  @override
  String toString() => message;
}
