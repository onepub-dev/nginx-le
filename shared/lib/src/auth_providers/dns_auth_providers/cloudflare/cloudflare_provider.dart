import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/generic_auth_provider.dart';
import 'package:nginx_le_shared/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../../../nginx_le_shared.dart';

class CloudFlareProvider extends GenericAuthProvider {
  static const _SETTING_API_TOKEN = 'cloudflare_api_token';
  static const ENV_API_TOKEN = 'ENV_API_TOKEN';

  final _settings = join('/tmp', 'cloudflare', 'settings.ini');

  @override
  String get name => 'cloudflare';
  @override
  String get summary => 'cloudflare dns provider';

  @override
  void auth_hook() {
    // no op
  }

  @override
  void cleanup_hook() {
    // no op
  }

  @override
  void pre_auth() {
    // no op
  }

  @override
  void promptForSettings(ConfigYaml config) {
    var cloudflare_api_token = ask(
      'Cloudflare API Token:',
      defaultValue: apiToken,
      validator: Ask.required,
    );
    apiToken = cloudflare_api_token;
  }

  String get apiToken => ConfigYaml().settings[_SETTING_API_TOKEN] as String;
  set apiToken(String apiToken) =>
      ConfigYaml().settings[_SETTING_API_TOKEN] = apiToken;

  @override
  List<EnvVar> get environment {
    var vars = <EnvVar>[];

    vars.add(EnvVar(ENV_API_TOKEN, apiToken));

    return vars;
  }

  @override
  void acquire() {
    var workDir = _createDir(Certbot.letsEncryptWorkPath);
    var logDir = _createDir(Certbot.letsEncryptLogPath);
    var configDir = _createDir(Certbot.letsEncryptConfigPath);
    createSettings();

    /// Pass environment vars down to the auth hook.
    Environment().logfile = join(logDir, 'letsencrypt.log');

    var emailaddress = Environment().emailaddress;
    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var staging = Environment().staging;
    var wildcard = Environment().wildcard;

    hostname = wildcard ? '*' : hostname;

    var certbot = 'certbot certonly '
        ' --dns-cloudflare '
        ' --dns-cloudflare-credentials $_settings'
        ' -m $emailaddress  '
        ' -d $hostname.$domain '
        ' --agree-tos '
        ' --manual-public-ip-logging-ok '
        ' --non-interactive '
        ' --work-dir=$workDir '
        ' --config-dir=$configDir '
        ' --logs-dir=$logDir ';

    if (staging) certbot += ' --staging ';

    var lines = <String>[];
    var progress = Progress((line) {
      print(line);
      lines.add(line);
    }, stderr: (line) {
      printerr(line);
      lines.add(line);
    });

    certbot.start(runInShell: true, nothrow: true, progress: progress);

    deleteSettings();

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

  void createSettings() {
    _createDir(dirname(_settings));

    _settings.write('dns_cloudflare_email = ${Environment().emailaddress}');
    _settings.append('dns_cloudflare_api_key = ${env(ENV_API_TOKEN)}');

    'chmod 600 $_settings'.run;
  }

  void deleteSettings() {
    delete(_settings);
  }
}
