/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:scope/scope.dart';

import '../../nginx_le_shared.dart';

class CertbotPaths {
  factory CertbotPaths() => _self;

  CertbotPaths._internal();

  static final CertbotPaths _self = CertbotPaths._internal();

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
  static const _nginxCertRoot = '/etc/nginx/certs/';
  static final nginxCertRootScopeKey = ScopeKey<String>('nginxCertRoot');
  String get nginxCertRoot =>
      _getScopedValue(nginxCertRootScopeKey, _nginxCertRoot);

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
  static const _certbotRootDefaultPath = '/etc/letsencrypt';
  static final certbotRootScopeKey = ScopeKey<String>('cerbotRoot');
  String get certbotRootDefaultPath =>
      _getScopedValue(certbotRootScopeKey, _certbotRootDefaultPath);

  /// The name of the logfile that certbot writes to.
  /// We also write our log messages to this file.
  final logFilename = 'letsencrypt.log';

  /// The path that nginx takes its home directory from.
  /// This is symlinked into either [wwwPathToOperating] or [wwwPathToAcquire]
  /// depending
  /// on whether we are in acquire or operational mode.
  static const _wwwPathLive = '/etc/nginx/live';
  static final wwwPathLiveScopeKey = ScopeKey<String>('wwwPathLive');
  String get wwwPathLive => _getScopedValue(wwwPathLiveScopeKey, _wwwPathLive);

  /// When [wwwPathLive] is symlinked to this path then
  /// we have a certificate and are running in operatational mode.
  static const _wwwPathToOperating = '/etc/nginx/operating';
  static final wwwPathToOperatingScopeKey =
      ScopeKey<String>('wwwPathToOperating');
  String get wwwPathToOperating =>
      _getScopedValue(wwwPathToOperatingScopeKey, _wwwPathToOperating);

  /// When [wwwPathLive] is symlinked to this path then
  /// we DO NOT have a certificate and are running in acquistion mode.
  static const _wwwPathToAcquire = '/etc/nginx/acquire';
  static final wwwPathToAcquireScopeKey = ScopeKey<String>('wwwPathToAcquire');
  String get wwwPathToAcquire =>
      _getScopedValue(wwwPathToAcquireScopeKey, _wwwPathToAcquire);

  static const _cloudFlareSettings =
      '/etc/letsencrypt/nj-cloudflare/settings.ini';
  static final cloudFlareSettingsScopeKey =
      ScopeKey<String>('cloudFlareSettings');
  String get cloudFlareSettings =>
      _getScopedValue(cloudFlareSettingsScopeKey, _cloudFlareSettings);

  /// Each time certbot creates a new certificate (excluding  the first one)
  ///  it places it in a 'number' path.
  ///
  /// In order of acquistion
  /// conifg/live/<fqdn>
  /// conifg/live/<fqdn-001>
  /// conifg/live/<fqdn-002>
  @visibleForTesting
  String latestCertificatePath(String? hostname, String domain,
      {required bool wildcard}) {
    final livepath = join(CertbotPaths().letsEncryptLivePath);
    // if no paths contain '-' then the base fqdn path is correct.

    var defaultPath =
        _liveDefaultPathForFQDN(hostname, domain, wildcard: wildcard);

    /// find all the dirs that begin with <fqdn> in the live directory.
    final paths = find('${Certificate.buildFQDN(hostname, domain)}*',
        workingDirectory: livepath,
        types: [FileSystemEntityType.directory]).toList();

    var max = 0;
    for (final path in paths) {
      if (path.contains('-')) {
        // onepub.org-0001
        // onepub.org-new
        // onepub.org-new-0001
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
  String _liveDefaultPathForFQDN(String? hostname, String domain,
      {required bool wildcard}) {
    final fqdn = wildcard ? domain : Certificate.buildFQDN(hostname, domain);
    return join(letsEncryptLivePath, fqdn);
  }

  /// The root directory for the certificate files of the given [hostname]
  ///  and [domain].
  String certificatePathRoot(String? hostname, String domain,
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

  String _getScopedValue(ScopeKey<String> key, String defaultValue) {
    if (Scope.hasScopeKey(key)) {
      return Scope.use(key);
    } else {
      return defaultValue;
    }
  }

  // Used for unit testing. Changes all of the paths to be
  // relative to [testDir]
  @visibleForTesting
  static void withTestScope(String testDir, void Function() action) {
    Scope()
      ..value(CertbotPaths.certbotRootScopeKey,
          splice(testDir, CertbotPaths().certbotRootDefaultPath))
      ..value(CertbotPaths.nginxCertRootScopeKey,
          splice(testDir, CertbotPaths().nginxCertRoot))
      ..value(CertbotPaths.wwwPathLiveScopeKey,
          splice(testDir, CertbotPaths().wwwPathLive))
      ..value(CertbotPaths.wwwPathToOperatingScopeKey,
          splice(testDir, CertbotPaths().wwwPathToOperating))
      ..value(CertbotPaths.wwwPathToAcquireScopeKey,
          splice(testDir, CertbotPaths().wwwPathToAcquire))
      ..value(CertbotPaths.cloudFlareSettingsScopeKey,
          splice(testDir, CertbotPaths().cloudFlareSettings))
      ..runSync(() {
        createDir(Scope.use(certbotRootScopeKey), recursive: true);
        createDir(Scope.use(nginxCertRootScopeKey), recursive: true);
        // createDir(Scope.use(wwwPathLiveScopeKey), recursive: true);
        createDir(Scope.use(wwwPathToOperatingScopeKey), recursive: true);
        createDir(Scope.use(wwwPathToAcquireScopeKey), recursive: true);

        action();
      });
  }

// Adds [absolutePath] to [basePath] by treating [absolutePath]
// as a relative path. We remove the leading path separator from [absolutePath]
  static String splice(String basePath, String absolutePath) {
    if (absolutePath.startsWith(rootPath)) {
      // ignore: parameter_assignments
      absolutePath = absolutePath.substring(1);
    }
    return join(basePath, absolutePath);
  }
}
