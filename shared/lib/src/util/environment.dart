import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/src/certbot/certbot.dart';

import '../nginx.dart';

class Environment {
  static final _self = Environment._internal();
  factory Environment() => _self;

  static const String NAMECHEAP_API_KEY = 'NAMECHEAP_API_KEY';
  static const String NAMECHEAP_API_USER = 'NAMECHEAP_API_USER';

  Environment._internal();

  bool get debug => env('DEBUG') == 'true';
  set debug(bool _debug) => setEnv('DEBUG', '$_debug');

  String get logfile => env('LOG_FILE');
  set logfile(String logfile) => setEnv('LOG_FILE', logfile);

  bool get certbotVerbose => env('CERTBOT_VERBOSE') == 'true';
  set certbotVerbose(bool certbotVerbose) =>
      setEnv('CERTBOT_VERBOSE', '$certbotVerbose');

  String get hostname => env('HOSTNAME');
  set hostname(String _hostname) => setEnv('HOSTNAME', _hostname);

  String get domain => env('DOMAIN');
  set domain(String domain) => setEnv('DOMAIN', domain);

  String get tld => env('TLD');
  set tld(String tld) => setEnv('TLD', tld);

  String get emailaddress => env('EMAIL_ADDRESS');
  set emailaddress(String emailaddress) =>
      setEnv('EMAIL_ADDRESS', emailaddress);

  String get mode => env('MODE');
  set mode(String mode) => setEnv('MODE', mode);

  bool get staging => (env('STAGING') ?? 'false') == 'true';
  set staging(bool staging) => setEnv('STAGING', '$staging');

  bool get autoAcquire => (env('AUTO_ACQUIRE') ?? 'true') == 'true';
  set autoAcquire(bool autoAcquire) => setEnv('AUTO_ACQUIRE', '$autoAcquire');

  String get namecheapApiKey => env('NAMECHEAP_API_KEY');
  set namecheapApiKey(String namecheapApiKey) =>
      setEnv('NAMECHEAP_API_KEY', namecheapApiKey);
  String get namecheapApiUser => env('NAMECHEAP_API_USER');
  set namecheapApiUser(String namecheapApiUser) =>
      setEnv('NAMECHEAP_API_USER', namecheapApiUser);

  String get certbotRoot => env(Certbot.LETSENCRYPT_ROOT_ENV);
  set certbotRoot(String letsencryptDir) =>
      setEnv(Certbot.LETSENCRYPT_ROOT_ENV, letsencryptDir);

  String get certbotDomain => env('CERTBOT_DOMAIN');
  set certbotDomain(String domain) => setEnv('CERTBOT_DOMAIN', domain);

  String get certbotValidation => env('CERTBOT_VALIDATION');
  set certbotValidation(String token) => setEnv('CERTBOT_VALIDATION', token);

  String get certbotToken => env('CERTBOT_TOKEN');
  set certbotToken(String token) => setEnv('CERTBOT_TOKEN', token);

  String get certbotRootOverwrite => env(Certbot.NGINX_CERT_ROOT_OVERWRITE);
  set certbotRootOverwrite(String overwriteDir) =>
      setEnv(Certbot.NGINX_CERT_ROOT_OVERWRITE, overwriteDir);

  String get certbotDNSAuthHookPath => env('CERTBOT_DNS_AUTH_HOOK_PATH');
  set certbotDNSAuthHookPath(String path) =>
      setEnv('CERTBOT_DNS_AUTH_HOOK_PATH', path);

  String get certbotDNSCleanupHookPath => env('CERTBOT_DNS_CLEANUP_HOOK_PATH');
  set certbotDNSCleanupHookPath(String path) =>
      setEnv('CERTBOT_DNS_CLEANUP_HOOK_PATH', path);

  int get certbotDNSRetries => int.tryParse(env('DNS_RETRIES') ?? '20') ?? 20;
  set certbotDNSRetries(int retries) => setEnv('DNS_RETRIES', 'retries');

  String get nginxAccessLogPath => env(Nginx.NGINX_ACCESS_LOG_ENV);
  set nginxAccessLogPath(String path) =>
      setEnv(Nginx.NGINX_ACCESS_LOG_ENV, path);

  String get nginxErrorLogPath => env(Nginx.NGINX_ERROR_LOG_ENV);
  set nginxErrorLogPath(String path) => setEnv(Nginx.NGINX_ERROR_LOG_ENV, path);

  String get nginxLocationIncludePath => env(Nginx.NGINX_LOCATION_INCLUDE_PATH);
  set nginxLocationIncludePath(String path) =>
      setEnv(Nginx.NGINX_LOCATION_INCLUDE_PATH, path);
}
