import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../nginx_le_shared.dart';
import '../config/ConfigYaml.dart';

abstract class AuthProvider {
  /// Generic AuthProvider environment variables.
  static const AUTH_PROVIDER_TOKEN = 'AUTH_PROVIDER_TOKEN';
  static const AUTH_PROVIDER_EMAIL_ADDRESS = 'AUTH_PROVIDER_EMAIL_ADDRESS';
  static const AUTH_PROVIDER_USERNAME = 'AUTH_PROVIDER_USERNAME';
  static const AUTH_PROVIDER_PASSWORD = 'AUTH_PROVIDER_PASSWORD';

  /// unique name of the provider used as the key
  String get name;

  /// Description of the provider which we display to the user to help them select the provider.
  String get summary;

  /// Provides a list of environment variables that must be passed into
  /// the docker container when it is created.
  List<EnvVar> get environment;

  void promptForSettings(ConfigYaml confi);

  /// Starts the process to acquire a certificate.
  void acquire();

  /// overload this method if your provide needs to to have a manual auth_hook called
  void auth_hook();

  /// overload this method if your provide needs to to have a manual cleanup hook called
  void cleanup_hook();

  /// Overload this method to indicate whether the auth provider can support
  /// authentication of wildcard certificates.
  bool get supportsWildCards;

  /// Overload this method to indicate if the auth provider supports a webserver
  /// operating on a private ip address (with no public access).
  bool get supportsPrivateMode;

  /// Settings stored in the configuration file
  String get configToken =>
      ConfigYaml().settings[AUTH_PROVIDER_TOKEN] as String;
  set configToken(String token) =>
      ConfigYaml().settings[AUTH_PROVIDER_TOKEN] = token;

  String get configEmailAddress =>
      ConfigYaml().settings[AUTH_PROVIDER_EMAIL_ADDRESS] as String;
  set configEmailAddress(String emailAddress) =>
      ConfigYaml().settings[AUTH_PROVIDER_EMAIL_ADDRESS] = emailAddress;

  String get configUsername =>
      ConfigYaml().settings[AUTH_PROVIDER_USERNAME] as String;
  set configUsername(String username) =>
      ConfigYaml().settings[AUTH_PROVIDER_USERNAME] = username;

  String get configPassword =>
      ConfigYaml().settings[AUTH_PROVIDER_PASSWORD] as String;
  set configPassword(String password) =>
      ConfigYaml().settings[AUTH_PROVIDER_PASSWORD] = password;

  /// Settings stored in environment variables.
  String get envToken => env[AUTH_PROVIDER_TOKEN];
  set envToken(String token) => env[AUTH_PROVIDER_TOKEN] = token;

  String get envEmailAddress => env[AUTH_PROVIDER_EMAIL_ADDRESS];
  set envEmailAddress(String emailAddress) =>
      env[AUTH_PROVIDER_EMAIL_ADDRESS] = emailAddress;

  String get envUsername => env[AUTH_PROVIDER_USERNAME];
  set envUsername(String username) => env[AUTH_PROVIDER_USERNAME] = username;

  String get envPassword => env[AUTH_PROVIDER_PASSWORD];
  set envPassword(String password) => env[AUTH_PROVIDER_PASSWORD] = password;

  void dumpEnvironmentVariables();

  void printEnv(String key, String value) {
    print('ENV: $key=$value');
  }
}
