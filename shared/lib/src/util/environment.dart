import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/certbot/certbot.dart';

import '../nginx.dart';

class Environment {
  static final _self = Environment._internal();

  factory Environment() => _self;

  static const String NAMECHEAP_API_KEY = 'NAMECHEAP_API_KEY';
  static const String NAMECHEAP_API_USER = 'NAMECHEAP_API_USER';

  Environment._internal();

  /// logging
  bool get debug => env['DEBUG'] == 'true';
  set debug(bool _debug) => env['DEBUG'] = '$_debug';

  String get logfile => env['LOG_FILE'];
  set logfile(String logfile) => env['LOG_FILE'] = logfile;

  /// domains

  /// if true we are using a wild card domain.
  bool get wildcard => (env['DOMAIN_WILDCARD'] ?? 'false') == 'true';
  set wildcard(bool wildcard) => env['DOMAIN_WILDCARD'] = '$wildcard';

  String get fqdn => '$hostname.$domain';

  String get hostname => env['HOSTNAME'];
  set hostname(String _hostname) => env['HOSTNAME'] = _hostname;

  String get domain => env['DOMAIN'];
  set domain(String domain) => env['DOMAIN'] = domain;

  String get tld => env['TLD'];
  set tld(String tld) => env['TLD'] = tld;

  /// modes
  String get mode => env['MODE'];
  set mode(String mode) => env['MODE'] = mode;

  bool get staging => (env['STAGING'] ?? 'false') == 'true';
  set staging(bool staging) => env['STAGING'] = '$staging';

  bool get autoAcquire => (env['AUTO_ACQUIRE'] ?? 'true') == 'true';

  set autoAcquire(bool autoAcquire) => env['AUTO_ACQUIRE'] = '$autoAcquire';

  // Mail
  String get emailaddress => env['EMAIL_ADDRESS'];
  set emailaddress(String emailaddress) => env['EMAIL_ADDRESS'] = emailaddress;

  String get smtpServer => env['SMTP_SERVER'];
  set smtpServer(String smtpServer) => env['SMTP_SERVER'] = smtpServer;

  int get smtpServerPort => int.tryParse(env['SMTP_SERVER_PORT'] ?? '25') ?? 25;
  set smtpServerPort(int smtpServerPort) =>
      env['SMTP_SERVER_PORT'] = '$smtpServerPort';

  // name cheap

  String get namecheapApiKey => env[NAMECHEAP_API_KEY];
  set namecheapApiKey(String namecheapApiKey) =>
      env[NAMECHEAP_API_KEY] = namecheapApiKey;
  String get namecheapApiUser => env[NAMECHEAP_API_USER];
  set namecheapApiUser(String namecheapApiUser) =>
      env[NAMECHEAP_API_USER] = namecheapApiUser;

  /// the certbot auth provider.
  String get certbotAuthProvider => env['CERTBOT_AUTH_PROVIDER'];
  set certbotAuthProvider(String certbotAuthProvider) =>
      env['CERTBOT_AUTH_PROVIDER'] = certbotAuthProvider;

  /// Certbot

  bool get certbotVerbose => env['CERTBOT_VERBOSE'] == 'true';
  set certbotVerbose(bool certbotVerbose) =>
      env['CERTBOT_VERBOSE'] = '$certbotVerbose';

  String get certbotRoot => env[Certbot.LETSENCRYPT_ROOT_ENV];
  set certbotRoot(String letsencryptDir) =>
      env[Certbot.LETSENCRYPT_ROOT_ENV] = letsencryptDir;

  String get certbotDomain => env['CERTBOT_DOMAIN'];
  set certbotDomain(String domain) => env['CERTBOT_DOMAIN'] = domain;

  String get certbotValidation => env['CERTBOT_VALIDATION'];
  set certbotValidation(String token) => env['CERTBOT_VALIDATION'] = token;

  String get certbotToken => env['CERTBOT_TOKEN'];
  set certbotToken(String token) => env['CERTBOT_TOKEN'] = token;

  /// passed in via the docker container
  String get certbotDNSAuthHookPath => env['CERTBOT_DNS_AUTH_HOOK_PATH'];
  set certbotDNSAuthHookPath(String certbotDNSAuthHookPath) =>
      env['CERTBOT_DNS_AUTH_HOOK_PATH'];
  String get certbotDNSCleanupHookPath => env['CERTBOT_DNS_CLEANUP_HOOK_PATH'];
  set certbotDNSCleanupHookPath(String certbotDNSCleanupHookPath) =>
      env['CERTBOT_DNS_CLEANUP_HOOK_PATH'];

  /// passed in via the docker container
  String get certbotHTTPAuthHookPath => env['CERTBOT_HTTP_AUTH_HOOK_PATH'];
  String get certbotHTTPCleanupHookPath =>
      env['CERTBOT_HTTP_CLEANUP_HOOK_PATH'];

  int get certbotDNSRetries => int.tryParse(env['DNS_RETRIES'] ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => env['DNS_RETRIES'] = 'retries';

  /// NGINX
  ///
  ///
  String get certbotRootPathOverwrite => env[Certbot.NGINX_CERT_ROOT_OVERWRITE];
  set certbotRootPathOverwrite(String overwriteDir) =>
      env[Certbot.NGINX_CERT_ROOT_OVERWRITE] = overwriteDir;

  String get nginxAccessLogPath => env[Nginx.NGINX_ACCESS_LOG_ENV];
  set nginxAccessLogPath(String path) => env[Nginx.NGINX_ACCESS_LOG_ENV] = path;

  String get nginxErrorLogPath => env[Nginx.NGINX_ERROR_LOG_ENV];
  set nginxErrorLogPath(String path) => env[Nginx.NGINX_ERROR_LOG_ENV] = path;

  String get nginxLocationIncludePath => env[Nginx.NGINX_LOCATION_INCLUDE_PATH];
  set nginxLocationIncludePath(String path) =>
      env[Nginx.NGINX_LOCATION_INCLUDE_PATH] = path;
}
