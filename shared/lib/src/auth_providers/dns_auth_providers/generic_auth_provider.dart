/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:strings/strings.dart';

import '../../../nginx_le_shared.dart';
import '../../util/create_dir.dart';

abstract class GenericAuthProvider extends AuthProvider {
  /// over load this method to do any checks before the acquire method is run.
  void preAuth() {}

  ///
  /// Acquires a Certbot certificate using DNS Auth.
  ///
  /// This class is designed to work with any DNS Provider that works via
  /// a manual auth hook and cleanup.
  ///
  /// It use the following environment variables to configure the auth
  ///
  /// ```dart
  ///  var emailaddress = Environment().emailaddress;
  ///  var hostname = Environment().hostname;
  ///  var domain = Environment().domain;
  ///  var production = Environment().production;
  ///
  ///  var auth_hook_path = Environment().certbotDNSAuthHookPath;
  ///  var cleanup_hook_path = Environment().certbotDNSCleanupHookPath;
  ///  ```
  @override
  void acquire() {
    final workDir = lcreateDir(CertbotPaths().letsEncryptWorkPath);
    final logDir = lcreateDir(CertbotPaths().letsEncryptLogPath);
    final configDir = lcreateDir(CertbotPaths().letsEncryptConfigPath);

    /// Pass environment vars down to the auth hook.
    Environment().logfile = join(logDir, 'letsencrypt.log');

    var hostname = Environment().hostname;
    final domain = Environment().domain;
    final aliases = Environment().aliases;
    final wildcard = Environment().domainWildcard;

    hostname = wildcard ? '*' : hostname;

    final fqdn = Certificate.buildFQDN(hostname, domain);

    final production = Environment().production;
    final emailaddress = Environment().authProviderEmailAddress;

    final authHookPath = Environment().certbotAuthHookPath;
    final cleanupHookPath = Environment().certbotCleanupHookPath;

    ArgumentError.checkNotNull(
        authHookPath,
        'Environment variable: '
        '${Environment.certbotAuthHookPathKey} missing');
    ArgumentError.checkNotNull(
        cleanupHookPath,
        'Environment variable: '
        '${Environment.certbotCleanupHookPathKey} missing');

    verbose(() => 'Starting cerbot with authProvider: $name');

    final domainList = StringBuffer()..write(fqdn);
    if (Strings.isNotEmpty(aliases)) {
      domainList.write(', $aliases');
    }

    NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
        .withLock(() {
      var certbot = '${Certbot.pathTo} certonly '
          ' --manual '
          ' --preferred-challenges=dns '
          ' -m $emailaddress  '
          ' -d $domainList '
          ' --agree-tos '
          ' --non-interactive '
          ' --manual-auth-hook="$authHookPath" '
          ' --manual-cleanup-hook="$cleanupHookPath" '
          ' --work-dir=$workDir '
          ' --config-dir=$configDir '
          ' --logs-dir=$logDir ';

      if (!production) {
        certbot += ' --staging ';
      }

      final lines = <String>[];
      final progress = Progress((line) {
        print(line);
        lines.add(line);
      }, stderr: (line) {
        printerr(line);
        lines.add(line);
      });

      certbot.start(runInShell: true, nothrow: true, progress: progress);

      if (progress.exitCode != 0) {
        final system = 'hostname'.firstLine;

        throw CertbotException(
            'certbot failed acquiring a certificate for '
            '$fqdn on $system',
            details: lines.join('\n'));
      }
    });
  }
}
