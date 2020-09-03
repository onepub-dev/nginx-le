import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/certbot/certbot.dart';

import '../nginx.dart';

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
  String get certbotAuthProviderKey => 'CERTBOT_AUTH_PROVIDER';
  String get certbotAuthProvider => env[certbotAuthProviderKey];
  set certbotAuthProvider(String certbotAuthProvider) =>
      env[certbotAuthProviderKey] = certbotAuthProvider;

  /// Certbot
  String get certbotVerboseKey => 'CERTBOT_VERBOSE';
  bool get certbotVerbose => env[certbotVerboseKey] == 'true';
  set certbotVerbose(bool certbotVerbose) =>
      env[certbotVerboseKey] = '$certbotVerbose';

  String get certbotRootKey => Certbot.LETSENCRYPT_ROOT_ENV;
  String get certbotRoot => env[certbotRootKey];
  set certbotRoot(String letsencryptDir) =>
      env[certbotRootKey] = letsencryptDir;

  String get certbotDomainKey => 'CERTBOT_DOMAIN';
  String get certbotDomain => env[certbotDomainKey];
  set certbotDomain(String domain) => env[certbotDomainKey] = domain;

  String get certbotValidationKey => 'CERTBOT_VALIDATION';
  String get certbotValidation => env[certbotValidationKey];
  set certbotValidation(String token) => env[certbotValidationKey] = token;

  String get certbotTokenKey => 'CERTBOT_TOKEN';
  String get certbotToken => env[certbotTokenKey];
  set certbotToken(String token) => env[certbotTokenKey] = token;

  /// passed in via the docker container
  String get certbotDNSAuthHookPathKey => 'CERTBOT_DNS_AUTH_HOOK_PATH';
  String get certbotDNSAuthHookPath => env[certbotDNSAuthHookPathKey];
  set certbotDNSAuthHookPath(String certbotDNSAuthHookPath) =>
      env[certbotDNSAuthHookPathKey];

  String get certbotDNSCleanupHookPathKey => 'CERTBOT_DNS_CLEANUP_HOOK_PATH';
  String get certbotDNSCleanupHookPath => env[certbotDNSCleanupHookPathKey];
  set certbotDNSCleanupHookPath(String certbotDNSCleanupHookPath) =>
      env[certbotDNSCleanupHookPathKey];

  /// passed in via the docker container
  String get certbotHTTPAuthHookPathKey => 'CERTBOT_HTTP_AUTH_HOOK_PATH';
  String get certbotHTTPAuthHookPath => env[certbotHTTPAuthHookPathKey];
  String get certbotHTTPCleanupHookPath => env[certbotHTTPAuthHookPathKey];

  String get certbotDNSRetriesKey => 'DNS_RETRIES';
  int get certbotDNSRetries =>
      int.tryParse(env[certbotDNSRetriesKey] ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => env[certbotDNSRetriesKey] = 'retries';

  /// NGINX
  ///
  ///
  String get certbotRootPathOverwrite => env[Certbot.NGINX_CERT_ROOT_OVERWRITE];
  set certbotRootPathOverwrite(String overwriteDir) =>
      env[Certbot.NGINX_CERT_ROOT_OVERWRITE] = overwriteDir;

  String get nginxAccessLogPath => env[Nginx.NGINX_ACCESS_LOG_PATH];
  set nginxAccessLogPath(String path) =>
      env[Nginx.NGINX_ACCESS_LOG_PATH] = path;

  String get nginxErrorLogPath => env[Nginx.NGINX_ERROR_LOG_PATH];
  set nginxErrorLogPath(String path) => env[Nginx.NGINX_ERROR_LOG_PATH] = path;

  String get nginxLocationIncludePath => env[Nginx.NGINX_LOCATION_INCLUDE_PATH];
  set nginxLocationIncludePath(String path) =>
      env[Nginx.NGINX_LOCATION_INCLUDE_PATH] = path;
}
