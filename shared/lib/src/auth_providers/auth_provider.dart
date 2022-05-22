import 'package:dcli/dcli.dart';

import '../../nginx_le_shared.dart';
import '../util/env_var.dart';

abstract class AuthProvider {
  /// Generic AuthProvider environment variables.
  // static const authProviderToken = 'AUTH_PROVIDER_TOKEN';
  // static const authProviderEmailAddress = 'AUTH_PROVIDER_EMAIL_ADDRESS';
  // static const authProviderUsername = 'AUTH_PROVIDER_USERNAME';
  // static const authProviderPassword = 'AUTH_PROVIDER_PASSWORD';

  /// unique name of the provider used as the key
  String get name;

  /// Description of the provider which we display to the user to help
  ///  them select the provider.
  String get summary;

  /// Provides a list of environment variables that must be passed into
  /// the docker container when it is created.
  List<EnvVar> get environment;

  void promptForSettings(ConfigYaml config);

  /// Starts the process to acquire a certificate.
  void acquire();

  /// overload this method if your provide needs to to have a manual
  /// auth_hook called
  void authHook();

  /// overload this method if your provide needs to to have a manual
  /// cleanup hook called
  void cleanupHook();

  /// Overload this method to indicate whether the auth provider can support
  /// authentication of wildcard certificates.
  bool get supportsWildCards;

  /// Overload this method to indicate if the auth provider supports a webserver
  /// operating on a private ip address (with no public access).
  bool get supportsPrivateMode;

  /// Settings stored in the configuration file
  String? get configToken =>
      ConfigYaml().settings[Environment.authProviderTokenKey] as String?;
  set configToken(String? token) =>
      ConfigYaml().settings[Environment.authProviderTokenKey] = token;

  String? get configEmailAddress =>
      ConfigYaml().settings[Environment.authProviderEmailAddressKey] as String?;
  set configEmailAddress(String? emailAddress) =>
      ConfigYaml().settings[Environment.authProviderEmailAddressKey] =
          emailAddress;

  String? get configUsername =>
      ConfigYaml().settings[Environment.authProviderUsernameKey] as String?;
  set configUsername(String? username) =>
      ConfigYaml().settings[Environment.authProviderUsernameKey] = username;

  String? get configPassword =>
      ConfigYaml().settings[Environment.authProviderTokenKey] as String?;
  set configPassword(String? password) =>
      ConfigYaml().settings[Environment.authProviderTokenKey] = password;

  /// Settings stored in environment variables.
  String? get envToken => env[Environment.authProviderTokenKey];
  set envToken(String? token) => env[Environment.authProviderTokenKey] = token;

  String? get envEmailAddress => Environment().authProviderEmailAddress;

  set envEmailAddress(String? emailAddress) =>
      Environment().authProviderEmailAddress = emailAddress;

  String? get envUsername => env[Environment.authProviderUsernameKey];
  set envUsername(String? username) =>
      env[Environment.authProviderUsernameKey] = username;

  void validateEnvironmentVariables();

  void printEnv(String key, String? value) {
    print('ENV: $key=$value');
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) =>
      other is AuthProvider &&
      other.runtimeType == runtimeType &&
      other.name == name;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => name.hashCode;
}
