import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../../nginx_le_shared.dart';

/// Provides wrappers to get/set environment variables to
/// ensure we are consistently using the same environment keys.
class Environment {
  static final _self = Environment._internal();

  factory Environment() => _self;

  Environment._internal();

  /// logging
  String get debugKey => 'DEBUG';
  bool get debug => env[debugKey] == 'true';

  set debug(bool _debug) => env[debugKey] = '$_debug';

  String get logfileKey => 'LOG_FILE';
  String get logfile => env['LOG_FILE'];
  set logfile(String logfile) => env['LOG_FILE'] = logfile;

  /// domains

  /// if true we are using a wild card domain.
  String get domainWildcardKey => 'DOMAIN_WILDCARD';
  bool get domainWildcard => (env[domainWildcardKey] ?? 'false') == 'true';
  set domainWildcard(bool wildcard) => env[domainWildcardKey] = '$wildcard';

  String get fqdn => '$hostname.$domain';

  String get hostnameKey => 'HOSTNAME';
  String get hostname => env[hostnameKey];
  set hostname(String _hostname) => env[hostnameKey] = _hostname;

  String get domainKey => 'DOMAIN';
  String get domain => env[domainKey];
  set domain(String domain) => env[domainKey] = domain;

  String get tldKey => 'TLD';
  String get tld => env[tldKey];
  set tld(String tld) => env[tldKey] = tld;

  String get startPausedKey => 'START_PAUSED';
  bool get startPaused => env[startPausedKey] == 'true';
  set startPaused(bool _debug) => env[startPausedKey] = '$_debug';

  String get productionKey => 'PRODUCTION';
  bool get production => (env[productionKey] ?? 'false') == 'true';
  set production(bool production) => env[productionKey] = '$production';

  String get autoAcquireKey => 'AUTO_ACQUIRE';
  bool get autoAcquire => (env[autoAcquireKey] ?? 'true') == 'true';
  set autoAcquire(bool autoAcquire) => env[autoAcquireKey] = '$autoAcquire';

  // Used to send to when an error occurs.
  String get emailaddressKey => 'EMAIL_ADDRESS';
  String get emailaddress => env[emailaddressKey];
  set emailaddress(String emailaddress) => env[emailaddressKey] = emailaddress;

  String get smtpServerKey => 'SMTP_SERVER';
  String get smtpServer => env[smtpServerKey];
  set smtpServer(String smtpServer) => env[smtpServerKey] = smtpServer;

  String get smtpServerPortKey => 'SMTP_SERVER_PORT';
  int get smtpServerPort => int.tryParse(env[smtpServerPortKey] ?? '25') ?? 25;
  set smtpServerPort(int smtpServerPort) =>
      env[smtpServerPortKey] = '$smtpServerPort';

  /// the certbot auth provider.
  String get authProviderKey => 'AUTH_PROVIDER';
  String get authProvider => env[authProviderKey];
  set authProvider(String authProvider) => env[authProviderKey] = authProvider;

  /// These environments variables are nomally set by the dockerfile
  /// We have these here for testing purposes only
  @visibleForTesting
  String get authProviderTokenKey => 'AUTH_PROVIDER_TOKEN';
  @visibleForTesting
  String get authProviderToken => env[authProviderTokenKey];
  @visibleForTesting
  set authProviderToken(String authProviderToken) =>
      env[authProviderTokenKey] = authProviderToken;

  @visibleForTesting
  String get authProviderUsernameKey => 'AUTH_PROVIDER_USERNAME';
  @visibleForTesting
  String get authProviderUsername => env[authProviderTokenKey];
  @visibleForTesting
  set authProviderUsername(String authProviderUsername) =>
      env[authProviderUsernameKey] = authProviderUsername;

  String get authProviderEmailAddressKey => 'AUTH_PROVIDER_EMAIL_ADDRESS';

  /// returns the value in [authProviderEmailAddressKey] if this is not set
  /// then returns [emailAddress].
  String get authProviderEmailAddress {
    var email = env[authProviderEmailAddressKey];

    return email ?? Environment().emailaddress;
  }

  set authProviderEmailAddress(String authProviderEmailAddress) =>
      env[authProviderEmailAddressKey] = authProviderEmailAddress;

  //  env['AUTH_PROVIDER_TOKEN'] = settings['AUTH_PROVIDER_TOKEN'] as String;
  //   env['AUTH_PROVIDER_EMAIL_ADDRESS'] = settings['AUTH_PROVIDER_TOKEN'] as String;

  /// Certbot
  String get certbotVerboseKey => 'CERTBOT_VERBOSE';
  bool get certbotVerbose => env[certbotVerboseKey] == 'true';
  set certbotVerbose(bool certbotVerbose) =>
      env[certbotVerboseKey] = '$certbotVerbose';

  String get certbotRootPathKey => 'CERTBOT_ROOT_PATH';
  String get certbotRootPath =>
      env[certbotRootPathKey] ?? CertbotPaths().CERTBOT_ROOT_DEFAULT_PATH;
  set certbotRootPath(String certbotRootPath) =>
      env[certbotRootPathKey] = certbotRootPath;

  String get certbotDomainKey => 'CERTBOT_DOMAIN';
  String get certbotDomain => env[certbotDomainKey];
  set certbotDomain(String domain) => env[certbotDomainKey] = domain;

  String get certbotValidationKey => 'CERTBOT_VALIDATION';
  String get certbotValidation => env[certbotValidationKey];
  set certbotValidation(String token) => env[certbotValidationKey] = token;

  String get certbotTokenKey => 'CERTBOT_TOKEN';
  String get certbotToken => env[certbotTokenKey];
  set certbotToken(String token) => env[certbotTokenKey] = token;

  String get certbotIgnoreBlockKey => 'CERTBOT_IGNORE_BLOCK';
  bool get certbotIgnoreBlock => env[certbotIgnoreBlockKey] == 'true';
  set certbotIgnoreBlock(bool flag) => env[certbotIgnoreBlockKey] = '$flag';

  String get certbotAuthHookPathKey => 'CERTBOT_AUTH_HOOK_PATH';
  String get certbotAuthHookPath => env[certbotAuthHookPathKey] ?? 'auth_hook';
  set certbotAuthHookPath(String certbotAuthHookPath) =>
      env[certbotAuthHookPathKey] = certbotAuthHookPath;

  String get certbotCleanupHookPathKey => 'CERTBOT_CLEANUP_HOOK_PATH';
  String get certbotCleanupHookPath =>
      env[certbotCleanupHookPathKey] ?? 'cleanup_hook';
  set certbotCleanupHookPath(String certbotCleanupHookPath) =>
      env[certbotCleanupHookPathKey] = certbotCleanupHookPath;

  String get certbotDeployHookPathKey => 'CERTBOT_DEPLOY_HOOK_PATH';
  String get certbotDeployHookPath =>
      env[certbotDeployHookPathKey] ?? 'deploy_hook';
  set certbotDeployHookPath(String certbotDeployHookPath) =>
      env[certbotDeployHookPathKey] = certbotDeployHookPath;

  /// when the deploy_hook is called as part of a renewal certbot passed
  /// the path to the directory containing the new certificate files.
  String get certbotDeployHookRenewedLineageKey => 'RENEWED_LINEAGE';
  String get certbotDeployHookRenewedLineagePath =>
      env[certbotDeployHookRenewedLineageKey];
  set certbotDeployHookRenewedLineagePath(
          String certbotDeployHookRenewedLineagePath) =>
      env[certbotDeployHookRenewedLineageKey] =
          certbotDeployHookRenewedLineagePath;

  String get certbotDNSRetriesKey => 'DNS_RETRIES';
  int get certbotDNSRetries =>
      int.tryParse(env[certbotDNSRetriesKey] ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => env[certbotDNSRetriesKey] = 'retries';

  /// NGINX
  ///
  ///
  String get nginxCertRootPathOverwriteKey => 'NGINX_CERT_ROOT_OVERWRITE';
  String get nginxCertRootPathOverwrite => env[nginxCertRootPathOverwriteKey];
  set nginxCertRootPathOverwrite(String overwriteDir) =>
      env[nginxCertRootPathOverwriteKey] = overwriteDir;

  String get nginxAccessLogPathKey => 'NGINX_ACCESS_LOG_PATH';
  String get nginxAccessLogPath => env[nginxAccessLogPathKey];
  set nginxAccessLogPath(String path) => env[nginxAccessLogPathKey] = path;

  String get nginxErrorLogPathKey => 'NGINX_ERROR_LOG_PATH';
  String get nginxErrorLogPath => env[nginxErrorLogPathKey];
  set nginxErrorLogPath(String path) => env[nginxErrorLogPathKey] = path;

  String get nginxLocationIncludePathKey => 'NGINX_LOCATION_INCLUDE_PATH';
  String get nginxLocationIncludePath => env[nginxLocationIncludePathKey];
  set nginxLocationIncludePath(String path) =>
      env[nginxLocationIncludePathKey] = path;
}
