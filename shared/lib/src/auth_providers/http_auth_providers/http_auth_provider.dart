import 'package:dcli/dcli.dart';

import '../../../nginx_le_shared.dart';
import '../../util/env_var.dart';

class HTTPAuthProvider extends AuthProvider {
  @override
  String get name => 'HTTP01Auth';

  @override
  String get summary =>
      'HTTP01Auth - Standard Certbot HTTP01 Auth. Port 80 must be open';

  @override
  void authHook(
      {String? hostname, String? domain, String? tld, String? emailaddress}) {
    Certbot().log('*' * 80);
    Certbot().log('certbot_http_auth_hook started');

    ///
    /// Get the environment vars passed to use
    ///
    final verbose = Environment().certbotVerbose;
    Certbot().log('verbose: $verbose');
    print('VERBOSE=$verbose');

    Settings().setVerbose(enabled: verbose);

    /// Certbot generated envs.
    // ignore: unnecessary_cast
    final fqdn = Environment().certbotDomain;
    Certbot().log('fqdn: $fqdn');
    Certbot()
        .log('${Environment().certbotTokenKey}: ${Environment().certbotToken}');
    print('${Environment().certbotTokenKey}: ${Environment().certbotToken}');
    Certbot().log('${Environment().certbotValidationKey}: '
        '${Environment().certbotValidation}');
    print('${Environment().certbotValidationKey}: '
        '${Environment().certbotValidation}');

    // ignore: unnecessary_cast
    final certbotAuthKey = Environment().certbotValidation;
    Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
    if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
      Certbot().logError(
          'The environment variable ${Environment().certbotValidationKey} '
          'was empty http_auth_hook ABORTED.');
    }
    ArgumentError.checkNotNull(
        certbotAuthKey,
        'The environment variable ${Environment().certbotValidationKey} '
        'was empty');

    final token = Environment().certbotToken;
    Certbot().log('token: "$token"');
    if (token == null || token.isEmpty) {
      Certbot().logError(
          'The environment variable ${Environment().certbotTokenKey} was '
          'empty http_auth_hook ABORTED.');
    }
    ArgumentError.checkNotNull(certbotAuthKey,
        'The environment variable ${Environment().certbotTokenKey} was empty');

    /// This path MUST match the path set in the nginx config files:
    /// /etc/nginx/operating/default.conf
    /// /etc/nginx/acquire/default.conf
    final path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
        'acme-challenge', token);
    print('writing token to $path');
    Certbot().log('writing token to $path');
    path.write(certbotAuthKey!);

    Certbot().log('certbot_http_auth_hook completed');
    Certbot().log('*' * 80);
  }

  @override
  void cleanupHook(
      {String? hostname, String? domain, String? tld, String? emailaddress}) {
    Certbot().log('*' * 80);
    Certbot().log('cert_bot_http_cleanup_hook started');

    ///
    /// Get the environment vars passed to use
    ///
    final verbose = Environment().certbotVerbose;
    Certbot().log('verbose: $verbose');

    Settings().setVerbose(enabled: verbose);
    ArgumentError.checkNotNull(Environment().certbotToken,
        'The environment variable ${Environment().certbotTokenKey} was empty');

    /// This path MUST match the path set in the nginx config files:
    /// /etc/nginx/operating/default.conf
    /// /etc/nginx/acquire/default.conf
    final path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
        Environment().certbotToken);
    if (exists(path)) {
      delete(path);
    }

    Certbot().log('cert_bot_http_cleanup_hook completed');
    Certbot().log('*' * 80);
  }

  @override
  void promptForSettings(ConfigYaml config) {
    /// no op
  }

  @override
  void acquire() {
    final workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    final logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    final configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    final emailaddress = Environment().authProviderEmailAddress;
    final hostname = Environment().hostname;
    final domain = Environment().domain;
    final production = Environment().production;

    /// These are set via in the Dockerfile
    final authHook = Environment().certbotAuthHookPath;
    final cleanupHook = Environment().certbotCleanupHookPath;

    ArgumentError.checkNotNull(
        authHook,
        'Environment variable: ${Environment().certbotAuthHookPathKey} '
        'missing');
    ArgumentError.checkNotNull(cleanupHook,
        'Environment variable: CERTBOT_HTTP_CLEANUP_HOOK_PATH missing');

    verbose(() => 'Starting cerbot with authProvider: $name');

    NamedLock(name: 'certbot', timeout: const Duration(minutes: 20))
        .withLock(() {
      var certbot = '${Certbot.pathTo} certonly '
          ' --manual '
          ' --preferred-challenges=http '
          ' -m $emailaddress  '
          ' -d ${Certificate.buildFQDN(hostname, domain)} '
          ' --agree-tos '
          ' --non-interactive '
          ' --manual-auth-hook="$authHook" '
          ' --manual-cleanup-hook="$cleanupHook" '
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
            '${Certificate.buildFQDN(hostname, domain)} '
            'on $system',
            details: lines.join('\n'));
      }
    });
  }

  String _createDir(String dir) {
    if (!exists(dir)) {
      createDir(dir, recursive: true);
    }
    return dir;
  }

  @override
  List<EnvVar> get environment => <EnvVar>[];

  @override
  bool get supportsPrivateMode => false;

  @override
  bool get supportsWildCards => false;

  @override
  void validateEnvironmentVariables() {
    printEnv(Environment().certbotAuthHookPathKey,
        Environment().certbotAuthHookPath);
  }
}
