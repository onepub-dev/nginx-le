/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:path/path.dart';
import 'package:strings/strings.dart';

import '../../../../nginx_le_shared.dart';
import '../../../util/create_dir.dart';
import '../../../util/env_var.dart';

class CloudFlareProvider extends GenericAuthProvider {
  @override
  String get name => 'cloudflare';
  @override
  String get summary => 'Cloudflare DNS Auth Provider';

  @override
  void authHook() {
    // no op
  }

  @override
  void cleanupHook() {
    // no op
  }

  @override
  void preAuth() {
    // no op
  }

  @override
  void promptForSettings(ConfigYaml config) {
    configToken = ask(
      'Cloudflare API Token:',
      defaultValue: configToken,
      validator: Ask.required,
    );

    configEmailAddress = ask(
      'Cloudflare API Email Address:',
      defaultValue: configEmailAddress,
      validator: Ask.required,
    );
  }

  @override
  List<EnvVar> get environment {
    final vars = <EnvVar>[
      EnvVar(Environment.authProviderTokenKey, configToken),
      EnvVar(Environment.authProviderEmailAddressKey, configEmailAddress)
    ];

    return vars;
  }

  @override
  void acquire() {
    final workDir = lcreateDir(CertbotPaths().letsEncryptWorkPath);
    final logDir = lcreateDir(CertbotPaths().letsEncryptLogPath);
    final configDir = lcreateDir(CertbotPaths().letsEncryptConfigPath);

    /// Pass environment vars down to the auth hook.
    Environment().logfile = join(logDir, 'letsencrypt.log');

    _createSettings();

    var hostname = Environment().hostname;
    final domain = Environment().domain;
    final aliases = Environment().aliases;
    final wildcard = Environment().domainWildcard;
    final production = Environment().production;
    final emailaddress = Environment().authProviderEmailAddress;

    hostname = wildcard ? '*' : hostname;
    final fqdn = Certificate.buildFQDN(hostname, domain);

    verbose(() => 'Starting cerbot with authProvider: $name to acquire a '
        '${production ? 'production' : 'staging'} certificate '
        'for $fqdn');

    verbose(() => 'Cloudflare api token. '
        'Env:${Environment.authProviderTokenKey}: $envToken');

    final domainList = StringBuffer()..write(fqdn);
    if (Strings.isNotEmpty(aliases)) {
      domainList.write(', $aliases');
    }

    NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
        .withLock(() {
      var certbot = '${Certbot.pathTo} certonly '
          ' --dns-cloudflare '
          ' --dns-cloudflare-propagation-seconds '
          '${Environment().certbotDNSWaitTime}'
          ' --dns-cloudflare-credentials ${CertbotPaths().cloudFlareSettings}'
          ' -m $emailaddress '
          ' -d $domainList '
          ' --agree-tos '
          ' --non-interactive '
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

      // We do not delete the settings file as the certbot renewal process
      // keeps a link to this file but not its contents. So the settings
      // file is required for renewals.
      //deleteSettings();

      if (progress.exitCode != 0) {
        final system = 'hostname'.firstLine;

        throw CertbotException(
            'certbot failed acquiring a certificate for '
            '$fqdn on $system',
            details: lines.join('\n'));
      } else {
        print('Certificate acquired.');
      }
    });
  }

  /// The cloudflare api provider requires an ini style file with the
  /// settings.
  /// This method creates that file.
  void _createSettings() {
    lcreateDir(dirname(CertbotPaths().cloudFlareSettings));

    // Only works with a cloudflare global api token.
    CertbotPaths().cloudFlareSettings.write('dns_cloudflare_api_key=$envToken');
    CertbotPaths()
        .cloudFlareSettings
        .append('dns_cloudflare_email=$envEmailAddress');

    'chmod 600 ${CertbotPaths().cloudFlareSettings}'.run;

    Environment().logfile!
      ..append('Created certbot settings.ini: ')
      ..append(read(CertbotPaths().cloudFlareSettings).toList().join('\n'));
  }

  // void deleteSettings() {
  //   delete(_settings);
  // }

  @override
  bool get supportsPrivateMode => true;

  @override
  bool get supportsWildCards => true;

  @override
  void validateEnvironmentVariables() {
    printEnv(Environment.authProviderTokenKey, envToken);
    printEnv(Environment.authProviderEmailAddressKey, envEmailAddress);

    if (Environment().authProviderToken == null) {
      printerr(red('No Auth Provider Token has been set. '
          'Check ${Environment.authProviderTokenKey} has been set'));
      exit(1);
    }

    if (Environment().authProviderEmailAddress == null) {
      printerr(red('No Auth Provider Email address has been set. '
          'Check ${Environment.authProviderEmailAddressKey} has been set'));
      exit(1);
    }
  }
}
