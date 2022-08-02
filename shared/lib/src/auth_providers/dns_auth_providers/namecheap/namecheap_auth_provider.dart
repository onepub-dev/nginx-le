/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart';

import '../../../../nginx_le_shared.dart';
import '../../../util/env_var.dart';
import 'dns_auth.dart';
import 'dns_cleanup.dart';

class NameCheapAuthProvider extends GenericAuthProvider {
  @override
  String get name => 'namecheap';

  @override
  String get summary => 'Namecheap DNS Auth Provider';

  @override
  void promptForSettings(ConfigYaml config) {
    configUsername = ask(
      'NameCheap API Username:',
      defaultValue: configUsername,
      validator: Ask.required,
    );

    configToken = ask(
      'NameCheap API Key:',
      defaultValue: configToken,
      hidden: true,
      validator: Ask.required,
    );
  }

  @override
  void preAuth() {
    ArgumentError.checkNotNull(
        envToken, 'Environment variable: AUTH_PROVIDER_TOKEN missing');
    ArgumentError.checkNotNull(
        envUsername, 'Environment variable: AUTH_PROVIDER_USERNAME missing');
  }

  @override
  void authHook() {
    namecheapDNSPath();
  }

  @override
  void cleanupHook() {
    namecheapDNSCleanup();
  }

  @override
  List<EnvVar> get environment {
    final vars = <EnvVar>[
      EnvVar(Environment.authProviderTokenKey, configToken),
      EnvVar(Environment.authProviderUsernameKey, configUsername)
    ];

    return vars;
  }

  @override
  bool get supportsPrivateMode => true;

  @override
  bool get supportsWildCards => true;

  @override
  void validateEnvironmentVariables() {
    printEnv(Environment.authProviderTokenKey, envToken);
    printEnv(Environment.authProviderUsernameKey, envUsername);

    if (Environment().authProviderToken == null) {
      printerr(red('No Auth Provider Token has been set. '
          'Check ${Environment.authProviderTokenKey} has been set'));
      exit(1);
    }

    if (Environment().authProviderUsername == null) {
      printerr(red('No Auth Provider Username has been set. '
          'Check ${Environment.authProviderUsernameKey} has been set'));
      exit(1);
    }
  }
}
