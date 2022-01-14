import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../../nginx_le_shared.dart';

class CertbotPaths {
  factory CertbotPaths() => _self;

  CertbotPaths._internal();

  static CertbotPaths _self = CertbotPaths._internal();

  /// The directory where lets encrypt stores its certificates.
  /// As we need to persist certificates between container restarts
  /// [wwwPathLive] lives under [certbotRootDefaultPath] and
  /// MUST be on a persistent volume so we don't loose the
  /// certificates each time we restart nginx.
  /// The full path is /etc/letsencrypt/config/live
  final _livePath = 'live';

  /// The directory where nginx loads its certificates from
  /// The deploy process copies certificates from the lets encrypt
  /// [wwwPathLive] to the [nginxCertRoot].
  final nginxCertRoot = '/etc/nginx/certs/';

  /// The file containing the concatenated certs.
  final fullchainFile = 'fullchain.pem';

  final chainFile = 'chain.pem';

  /// our private key.
  final privateKeyFile = 'privkey.pem';

  /// certificate file
  final certificateFile = 'cert.pem';

  /// The directory where lets encrypt stores its certificates.
  /// As we need to persist certificates between container restarts
  /// the CERTBOT_ROOT_DEFAULT_PATH path is mounted to a persistent volume on
  ///  start up.
  final certbotRootDefaultPath = '/etc/letsencrypt';

  /// The name of the logfile that certbot writes to.
  /// We also write our log messages to this file.
  final logFilename = 'letsencrypt.log';

  /// The path that nginx takes its home directory from.
  /// This is symlinked into either [wwwPathToOperating] or [wwwPathToAcquire]
  /// depending
  /// on whether we are in acquire or operational mode.
  final wwwPathLive = '/etc/nginx/live';

  /// When [wwwPathLive] is symlinked to this path then
  /// we have a certificate and are running in operatational mode.
  final wwwPathToOperating = '/etc/nginx/operating';

  /// When [wwwPathLive] is symlinked to this path then
  /// we DO NOT have a certificate and are running in acquistion mode.
  final wwwPathToAcquire = '/etc/nginx/acquire';

  final cloudFlareSettings =
      join('/etc', 'letsencrypt', 'nj-cloudflare', 'settings.ini');

  /// Each time certbot creates a new certificate (excluding  the first one)
  ///  it places it in a 'number' path.
  ///
  /// In order of acquistion
  /// conifg/live/<fqdn>
  /// conifg/live/<fqdn-001>
  /// conifg/live/<fqdn-002>
  @visibleForTesting
  String latestCertificatePath(String? hostname, String? domain,
      {required bool wildcard}) {
    final livepath = join(CertbotPaths().letsEncryptLivePath);
    // if no paths contain '-' then the base fqdn path is correct.

    var defaultPath =
        _liveDefaultPathForFQDN(hostname, domain, wildcard: wildcard);

    /// find all the dirs that begin with <fqdn> in the live directory.
    final paths = find('$hostname.$domain*',
        workingDirectory: livepath,
        types: [FileSystemEntityType.directory]).toList();

    var max = 0;
    for (final path in paths) {
      if (path.contains('-')) {
        // noojee.org-0001
        // noojee.org-new
        // noojee.org-new-0001
        final parts = path.split('-');
        final num = int.tryParse(parts[parts.length - 1]);
        if (num == null) {
          if (max == 0) {
            /// a number path takes precendence over a non-numbered path
            defaultPath = join(livepath, path);
          }
        } else if (num > max) {
          max = num;
          defaultPath = join(livepath, path);
        }
      }
    }

    return defaultPath;
  }

  /// Returns the default path where lets encrypt certificates are stored.
  /// By default the path is /config/live/<fqdn> however lets
  /// encrypt adds a number designator when new certificates are aquired.
  ///
  /// See: [lastestCertificatePath()] for details.
  String _liveDefaultPathForFQDN(String? hostname, String? domain,
      {required bool wildcard}) {
    final fqdn = wildcard ? domain : '$hostname.$domain';
    return join(letsEncryptLivePath, fqdn);
  }

  /// The root directory for the certificate files of the given [hostname]
  ///  and [domain].
  String certificatePathRoot(String? hostname, String? domain,
          {required bool wildcard}) =>
      latestCertificatePath(hostname, domain, wildcard: wildcard);

  /// The path to the active fullchain.pem file in the live directory.
  String fullChainPath(String certificateRootPath) =>
      join(certificateRootPath, fullchainFile);

  /// The path to the active privatekey.pem file in the live directory
  String privateKeyPath(String certificateRootPath) =>
      join(certificateRootPath, privateKeyFile);

  /// path to the active certificate in the live directory
  String certificatePath(String certificateRootPath) =>
      join(certificateRootPath, certificateFile);

  String get letsEncryptRootPath => Environment().certbotRootPath;

  String get letsEncryptWorkPath => join(letsEncryptRootPath, 'work');

  String get letsEncryptLogPath => join(letsEncryptRootPath, 'logs');

  String get letsEncryptConfigPath => join(letsEncryptRootPath, 'config');

  /// path to the directory where the active certificates
  /// are stored.
  String get letsEncryptLivePath =>
      join(letsEncryptRootPath, 'config', _livePath);

  String get nginxCertPath {
    var path = Environment().nginxCertRootPathOverwrite;

    return path ??= CertbotPaths().nginxCertRoot;
  }

  @visibleForTesting
  // ignore: avoid_setters_without_getters
  static set moke(CertbotPaths mock) {
    _self = mock;
  }
}
