import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

import '../../../nginx_le_shared.dart';
import '../../certbot/certbot.dart';
import '../auth_provider.dart';

class HTTPAuthProvider extends AuthProvider {
  @override
  String get name => 'HTTP01Auth';

  @override
  String get summary =>
      'HTTP01Auth - Standard Certbot HTTP01 Auth. Port 80 must be open';

  @override
  void auth_hook(
      {String hostname, String domain, String tld, String emailaddress}) {
    Certbot().log('*' * 80);
    Certbot().log('certbot_http_auth_hook started');

    ///
    /// Get the environment vars passed to use
    ///
    var verbose = Environment().certbotVerbose;
    Certbot().log('verbose: $verbose');
    print('VERBOSE=$verbose');

    Settings().setVerbose(enabled: verbose);

    /// Certbot generated envs.
    // ignore: unnecessary_cast
    var fqdn = Environment().certbotDomain;
    Certbot().log('fqdn: $fqdn');
    Certbot()
        .log('${Environment().certbotTokenKey}: ${Environment().certbotToken}');
    print('${Environment().certbotTokenKey}: ${Environment().certbotToken}');
    Certbot().log(
        '${Environment().certbotValidationKey}: ${Environment().certbotValidation}');
    print(
        '${Environment().certbotValidationKey}: ${Environment().certbotValidation}');

    // ignore: unnecessary_cast
    var certbotAuthKey = Environment().certbotValidation;
    Certbot().log('CertbotAuthKey: "$certbotAuthKey"');
    if (certbotAuthKey == null || certbotAuthKey.isEmpty) {
      Certbot().logError(
          'The environment variable ${Environment().certbotValidationKey} was empty http_auth_hook ABORTED.');
    }
    ArgumentError.checkNotNull(certbotAuthKey,
        'The environment variable ${Environment().certbotValidationKey} was empty');

    var token = Environment().certbotToken;
    Certbot().log('token: "$token"');
    if (token == null || token.isEmpty) {
      Certbot().logError(
          'The environment variable ${Environment().certbotTokenKey} was empty http_auth_hook ABORTED.');
    }
    ArgumentError.checkNotNull(certbotAuthKey,
        'The environment variable ${Environment().certbotTokenKey} was empty');

    /// This path MUST match the path set in the nginx config files:
    /// /etc/nginx/custom/default.conf
    /// /etc/nginx/acquire/default.conf
    var path = join('/', 'opt', 'letsencrypt', 'wwwroot', '.well-known',
        'acme-challenge', token);
    print('writing token to $path');
    Certbot().log('writing token to $path');
    path.write(certbotAuthKey);

    Certbot().log('certbot_http_auth_hook completed');
    Certbot().log('*' * 80);
  }

  @override
  void cleanup_hook(
      {String hostname, String domain, String tld, String emailaddress}) {
    certbot_http_cleanup_hook();
  }

  @override
  void promptForSettings(ConfigYaml settings) {
    /// no op
  }

  @override
  void acquire() {
    var workDir = _createDir(Certbot.letsEncryptWorkPath);
    var logDir = _createDir(Certbot.letsEncryptLogPath);
    var configDir = _createDir(Certbot.letsEncryptConfigPath);

    var emailaddress = Environment().emailaddress;
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var production = Environment().production;

    /// These are set via in the Dockerfile
    var auth_hook = Environment().certbotHTTPAuthHookPath;
    var cleanup_hook = Environment().certbotHTTPCleanupHookPath;

    ArgumentError.checkNotNull(auth_hook,
        'Environment variable: ${Environment().certbotHTTPAuthHookPathKey} missing');
    ArgumentError.checkNotNull(cleanup_hook,
        'Environment variable: CERTBOT_HTTP_CLEANUP_HOOK_PATH missing');

    Settings().verbose('Starting cerbot with authProvider: $name');

    var certbot = 'certbot certonly '
        ' --manual '
        ' --preferred-challenges=http '
        ' -m $emailaddress  '
        ' -d $hostname.$domain '
        ' --agree-tos '
        ' --manual-public-ip-logging-ok '
        ' --non-interactive '
        ' --manual-auth-hook="$auth_hook" '
        ' --manual-cleanup-hook="$cleanup_hook" '
        ' --work-dir=$workDir '
        ' --config-dir=$configDir '
        ' --logs-dir=$logDir ';

    if (!production) certbot += ' --staging ';

    var lines = <String>[];
    var progress = Progress((line) {
      print(line);
      lines.add(line);
    }, stderr: (line) {
      printerr(line);
      lines.add(line);
    });

    certbot.start(runInShell: true, nothrow: true, progress: progress);

    if (progress.exitCode != 0) {
      var system = 'hostname'.firstLine;

      throw CertbotException(
          'certbot failed acquiring a certificate for $hostname.$domain on $system',
          details: lines.join('\n'));
    }
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
  void dumpEnvironmentVariables() {
    /// none.
  }
}
