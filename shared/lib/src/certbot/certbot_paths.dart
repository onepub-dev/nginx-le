import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../../nginx_le_shared.dart';

class CertbotPaths {
  static final CertbotPaths _self = CertbotPaths._internal();

  /// The directory where lets encrypt stores its certificates.
  /// As we need to persist certificates between container restarts
  /// [LIVE_PATH] lives under [CERTBOT_ROOT_PATH] and
  /// MUST be on a persistent volume so we don't loose the
  /// certificates each time we restart nginx.
  /// The full path is /etc/letsencrypt/config/live
  final _LIVE_PATH = 'live';

  /// The directory where nginx loads its certificates from
  /// The deploy process copies certificates from the lets encrypt
  /// [LIVE_PATH] to the [NGINX_CERT_ROOT].
  final NGINX_CERT_ROOT = '/etc/nginx/certs/';

  /// The file containing the concatenated certs.
  final FULLCHAIN_FILE = 'fullchain.pem';

  final CHAIN_FILE = 'chain.pem';

  /// our private key.
  final PRIVATE_KEY_FILE = 'privkey.pem';

  /// certificate file
  final CERTIFICATE_FILE = 'cert.pem';

  /// The directory where lets encrypt stores its certificates.
  /// As we need to persist certificates between container restarts
  /// the CERTBOT_ROOT_DEFAULT_PATH path is mounted to a persistent volume on start up.
  final CERTBOT_ROOT_DEFAULT_PATH = '/etc/letsencrypt';

  /// The name of the logfile that certbot writes to.
  /// We also write our log messages to this file.
  final LOG_FILE_NAME = 'letsencrypt.log';

  /// The path that nginx takes its home directory from.
  /// This is symlinked into either [WWW_PATH_OPERATING] or [WWW_PATH_ACQUIRE] depending
  /// on whether we are in acquire or operational mode.
  final WWW_PATH_LIVE = '/etc/nginx/live';

  /// When [WWW_PATH_LIVE] is symlinked to this path then
  /// we have a certificate and are running in operatational mode.
  final WWW_PATH_OPERATING = '/etc/nginx/custom';

  /// When [WWW_PATH_LIVE] is symlinked to this path then
  /// we DO NOT have a certificate and are running in acquistion mode.
  final WWW_PATH_ACQUIRE = '/etc/nginx/acquire';

  factory CertbotPaths() => _self;

  CertbotPaths._internal();

  /// Each time certbot creates a new certificate (excluding  the first one)
  ///  it places it in a 'number' path.
  ///
  /// In order of acquistion
  /// conifg/live/<fqdn>
  /// conifg/live/<fqdn-001>
  /// conifg/live/<fqdn-002>
  @visibleForTesting
  String latestCertificatePath(String hostname, String domain,
      {@required bool wildcard}) {
    var livepath = join(CertbotPaths().letsEncryptLivePath);
    // if no paths contain '-' then the base fqdn path is correct.

    var defaultPath =
        _liveDefaultPathForFQDN(hostname, domain, wildcard: wildcard);

    /// find all the dirs that begin with <fqdn> in the live directory.
    var paths = find('$hostname.$domain*',
        workingDirectory: livepath,
        types: [FileSystemEntityType.directory]).toList();

    var max = 0;
    for (var path in paths) {
      if (path.contains('-')) {
        // noojee.org-0001
        // noojee.org-new
        // noojee.org-new-0001
        var parts = path.split('-');
        var num = int.tryParse(parts[parts.length - 1]);
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
  /// See: [lastestCertificatePath] for details.
  String _liveDefaultPathForFQDN(String hostname, String domain,
      {@required bool wildcard}) {
    var fqdn = wildcard ? domain : '$hostname.$domain';
    return join(letsEncryptLivePath, fqdn);
  }

  /// The root directory for the certificate files of the given [hostname] and [domain].
  String certificatePathRoot(String hostname, String domain,
      {@required bool wildcard}) {
    return latestCertificatePath(hostname, domain, wildcard: wildcard);
  }

  /// The path to the active fullchain.pem file in the live directory.
  String fullChainPath(String certificateRootPath) {
//     getLatest
    return join(certificateRootPath, FULLCHAIN_FILE);
  }

  /// The path to the active privatekey.pem file in the live directory
  String privateKeyPath(String certificateRootPath) {
    return join(certificateRootPath, PRIVATE_KEY_FILE);
  }

  /// path to the active certificate in the live directory
  String certificatePath(String certificateRootPath) {
    return join(certificateRootPath, CERTIFICATE_FILE);
  }

  String get letsEncryptRootPath {
    /// allows the root to be over-ridden to make testing easier.
    return Environment().certbotRootPath;
  }

  String get letsEncryptWorkPath {
    return join(letsEncryptRootPath, 'work');
  }

  String get letsEncryptLogPath {
    return join(letsEncryptRootPath, 'logs');
  }

  String get letsEncryptConfigPath {
    return join(letsEncryptRootPath, 'config');
  }

  /// path to the directory where the active certificates
  /// are stored.
  String get letsEncryptLivePath {
    return join(letsEncryptRootPath, 'config', _LIVE_PATH);
  }

  String get nginxCertPath {
    var path = Environment().nginxCertRootPathOverwrite;

    path ??= CertbotPaths().NGINX_CERT_ROOT;
    return path;
  }
}
