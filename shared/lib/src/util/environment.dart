/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import '../../nginx_le_shared.dart';

/// Provides wrappers to get/set environment variables to
/// ensure we are consistently using the same environment keys.
class Environment {
  factory Environment() => _self;
  Environment._internal();

  static final _self = Environment._internal();

  /// logging
  static const String debugKey = 'DEBUG';
  bool get debug => env[debugKey] == 'true';

  set debug(bool _debug) => env[debugKey] = '$_debug';

  static const logfileKey = 'LOG_FILE';
  String? get logfile => env['LOG_FILE'];
  set logfile(String? logfile) => env['LOG_FILE'] = logfile;

  /// domains

  /// if true we are using a wild card domain.
  static const domainWildcardKey = 'DOMAIN_WILDCARD';
  bool get domainWildcard => (env[domainWildcardKey] ?? 'false') == 'true';
  set domainWildcard(bool wildcard) => env[domainWildcardKey] = '$wildcard';

  String get fqdn => Certificate.buildFQDN(hostname, domain);

  static const hostnameKey = 'HOSTNAME';
  String? get hostname => env[hostnameKey];
  set hostname(String? _hostname) => env[hostnameKey] = _hostname;

  static const domainKey = 'DOMAIN';
  String get domain {
    final dom = env[domainKey];
    if (dom == null) {
      throw CertbotException('The environment variable $domainKey was null');
    }
    return dom;
  }

  set domain(String? domain) => env[domainKey] = domain;

  static const tldKey = 'TLD';
  String? get tld => env[tldKey];
  set tld(String? tld) => env[tldKey] = tld;

  static const startPausedKey = 'START_PAUSED';
  bool get startPaused => env[startPausedKey] == 'true';
  set startPaused(bool _debug) => env[startPausedKey] = '$_debug';

  String get productionKey => 'PRODUCTION';
  bool get production => (env[productionKey] ?? 'false') == 'true';
  set production(bool production) => env[productionKey] = '$production';

  static const autoAcquireKey = 'AUTO_ACQUIRE';
  bool get autoAcquire => (env[autoAcquireKey] ?? 'true') == 'true';
  set autoAcquire(bool autoAcquire) => env[autoAcquireKey] = '$autoAcquire';

  // Used to send to when an error occurs.
  static const emailaddressKey = 'EMAIL_ADDRESS';
  String? get emailaddress => env[emailaddressKey];
  set emailaddress(String? emailaddress) => env[emailaddressKey] = emailaddress;

  static const smtpServerKey = 'SMTP_SERVER';
  String? get smtpServer => env[smtpServerKey];
  set smtpServer(String? smtpServer) => env[smtpServerKey] = smtpServer;

  static const smtpServerPortKey = 'SMTP_SERVER_PORT';
  int get smtpServerPort => int.tryParse(env[smtpServerPortKey] ?? '25') ?? 25;
  set smtpServerPort(int smtpServerPort) =>
      env[smtpServerPortKey] = '$smtpServerPort';

  /// the certbot auth provider.
  static const authProviderKey = 'AUTH_PROVIDER';
  String? get authProvider => env[authProviderKey];
  set authProvider(String? authProvider) => env[authProviderKey] = authProvider;

  /// These environments variables are nomally set by the dockerfile
  /// We have these here for testing purposes only
  static const authProviderTokenKey = 'AUTH_PROVIDER_TOKEN';
  String? get authProviderToken => env[authProviderTokenKey];
  @visibleForTesting
  set authProviderToken(String? authProviderToken) =>
      env[authProviderTokenKey] = authProviderToken;

  static const authProviderUsernameKey = 'AUTH_PROVIDER_USERNAME';
  String? get authProviderUsername => env[authProviderTokenKey];
  @visibleForTesting
  set authProviderUsername(String? authProviderUsername) =>
      env[authProviderUsernameKey] = authProviderUsername;

  static const authProviderEmailAddressKey = 'AUTH_PROVIDER_EMAIL_ADDRESS';

  /// returns the value in [authProviderEmailAddressKey] if this is not set
  /// then returns [emailaddress].
  String? get authProviderEmailAddress {
    final email = env[authProviderEmailAddressKey];

    return email ?? Environment().emailaddress;
  }

  set authProviderEmailAddress(String? authProviderEmailAddress) =>
      env[authProviderEmailAddressKey] = authProviderEmailAddress;

  /// Certbot
  static const certbotVerboseKey = 'CERTBOT_VERBOSE';
  bool get certbotVerbose => env[certbotVerboseKey] == 'true';
  set certbotVerbose(bool certbotVerbose) =>
      env[certbotVerboseKey] = '$certbotVerbose';

  static const certbotRootPathKey = 'CERTBOT_ROOT_PATH';
  String get certbotRootPath =>
      env[certbotRootPathKey] ?? CertbotPaths().certbotRootDefaultPath;
  set certbotRootPath(String certbotRootPath) =>
      env[certbotRootPathKey] = certbotRootPath;

  static const certbotDomainKey = 'CERTBOT_DOMAIN';
  String? get certbotDomain => env[certbotDomainKey];
  set certbotDomain(String? domain) => env[certbotDomainKey] = domain;

  static const certbotValidationKey = 'CERTBOT_VALIDATION';
  String? get certbotValidation => env[certbotValidationKey];
  set certbotValidation(String? token) => env[certbotValidationKey] = token;

  static const certbotTokenKey = 'CERTBOT_TOKEN';
  String? get certbotToken => env[certbotTokenKey];
  set certbotToken(String? token) => env[certbotTokenKey] = token;

  static const certbotIgnoreBlockKey = 'CERTBOT_IGNORE_BLOCK';
  bool get certbotIgnoreBlock => env[certbotIgnoreBlockKey] == 'true';
  set certbotIgnoreBlock(bool flag) => env[certbotIgnoreBlockKey] = '$flag';

  static const certbotAuthHookPathKey = 'CERTBOT_AUTH_HOOK_PATH';
  String get certbotAuthHookPath => env[certbotAuthHookPathKey] ?? 'auth_hook';
  set certbotAuthHookPath(String certbotAuthHookPath) =>
      env[certbotAuthHookPathKey] = certbotAuthHookPath;

  static const certbotCleanupHookPathKey = 'CERTBOT_CLEANUP_HOOK_PATH';
  String get certbotCleanupHookPath =>
      env[certbotCleanupHookPathKey] ?? 'cleanup_hook';
  set certbotCleanupHookPath(String certbotCleanupHookPath) =>
      env[certbotCleanupHookPathKey] = certbotCleanupHookPath;

  static const certbotDeployHookPathKey = 'CERTBOT_DEPLOY_HOOK_PATH';
  String get certbotDeployHookPath =>
      env[certbotDeployHookPathKey] ?? 'deploy_hook';
  set certbotDeployHookPath(String certbotDeployHookPath) =>
      env[certbotDeployHookPathKey] = certbotDeployHookPath;

  /// when the deploy_hook is called as part of a renewal, certbot passes
  /// the path to the directory containing the new certificate files.
  static const certbotDeployHookRenewedLineageKey = 'RENEWED_LINEAGE';
  String? get certbotDeployHookRenewedLineagePath =>
      env[certbotDeployHookRenewedLineageKey];
  set certbotDeployHookRenewedLineagePath(
          String? certbotDeployHookRenewedLineagePath) =>
      env[certbotDeployHookRenewedLineageKey] =
          certbotDeployHookRenewedLineagePath;

  static const certbotDNSRetriesKey = 'DNS_RETRIES';
  int get certbotDNSRetries =>
      int.tryParse(env[certbotDNSRetriesKey] ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => env[certbotDNSRetriesKey] = '$retries';

  // the amount of time (in seconds) to wait for dns changes to propergate
  // Used when doing DNS auth so that certbot doesn't try to auth before
  // the dns settings have propergated.
  static const certbotDNSWaitTimeKey = 'DNS_WAITTIME';
  int get certbotDNSWaitTime =>
      int.tryParse(env[certbotDNSWaitTimeKey] ?? '20') ?? 20;
  set certbotDNSWaitTime(int seconds) =>
      env[certbotDNSWaitTimeKey] = '$seconds';

  /// NGINX
  ///
  ///
  static const nginxCertRootPathOverwriteKey = 'NGINX_CERT_ROOT_OVERWRITE';
  String? get nginxCertRootPathOverwrite => env[nginxCertRootPathOverwriteKey];
  set nginxCertRootPathOverwrite(String? overwriteDir) =>
      env[nginxCertRootPathOverwriteKey] = overwriteDir;

  static const nginxAccessLogPathKey = 'NGINX_ACCESS_LOG_PATH';
  String? get nginxAccessLogPath => env[nginxAccessLogPathKey];
  set nginxAccessLogPath(String? path) => env[nginxAccessLogPathKey] = path;

  static const nginxErrorLogPathKey = 'NGINX_ERROR_LOG_PATH';
  String? get nginxErrorLogPath => env[nginxErrorLogPathKey];
  set nginxErrorLogPath(String? path) => env[nginxErrorLogPathKey] = path;

  static const nginxLocationIncludePathKey = 'NGINX_LOCATION_INCLUDE_PATH';
  String? get nginxLocationIncludePath => env[nginxLocationIncludePathKey];
  set nginxLocationIncludePath(String? path) =>
      env[nginxLocationIncludePathKey] = path;
}
