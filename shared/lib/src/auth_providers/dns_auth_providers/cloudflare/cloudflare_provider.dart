import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/generic_auth_provider.dart';
import 'package:nginx_le_shared/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../../../nginx_le_shared.dart';

class CloudFlareProvider extends GenericAuthProvider {
  final _settings = join('/tmp', 'cloudflare', 'settings.ini');

  @override
  String get name => 'cloudflare';
  @override
  String get summary => 'Cloudflare DNS Auth Provider';

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
    configToken = ask(
      'Cloudflare API Token:',
      defaultValue: configToken,
      validator: Ask.required,
    );

    configEmailAddress = ask(
      'Cloudflare API Email Address:',
      defaultValue: configEmailAddress,
      validator: Ask.required,
    );
  }

  @override
  List<EnvVar> get environment {
    var vars = <EnvVar>[];

    vars.add(EnvVar(AuthProvider.AUTH_PROVIDER_TOKEN, configToken));
    vars.add(
        EnvVar(AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS, configEmailAddress));

    return vars;
  }

  @override
  void acquire() {
    var workDir = _createDir(CertbotPaths().letsEncryptWorkPath);
    var logDir = _createDir(CertbotPaths().letsEncryptLogPath);
    var configDir = _createDir(CertbotPaths().letsEncryptConfigPath);

    /// Pass environment vars down to the auth hook.
    Environment().logfile = join(logDir, 'letsencrypt.log');

    _createSettings();

    var hostname = Environment().hostname;
    var domain = Environment().domain;
    var wildcard = Environment().domainWildcard;
    var production = Environment().production;
    var emailaddress = Environment().authProviderEmailAddress;

    hostname = wildcard ? '*' : hostname;

    Settings().verbose('Starting cerbot with authProvider: $name to acquire a '
        '${production ? 'production' : 'staging'} certificate for $hostname.$domain');

    Settings().verbose(
        'Cloudflare api token. Env:${AuthProvider.AUTH_PROVIDER_TOKEN}: $envToken');

    NamedLock(name: 'certbot', timeout: Duration(minutes: 20)).withLock(() {
      var certbot = 'certbot certonly '
          ' --dns-cloudflare '
          ' --dns-cloudflare-credentials $_settings'
          ' -m $emailaddress '
          ' -d $hostname.$domain '
          ' --agree-tos '
          ' --manual-public-ip-logging-ok '
          ' --non-interactive '
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

      // We do not delete the settings file as the certbot renewal process
      // keeps a link to this file but not its contents. So the settings
      // file is required for renewals.
      //deleteSettings();

      if (progress.exitCode != 0) {
        var system = 'hostname'.firstLine;

        throw CertbotException(
            'certbot failed acquiring a certificate for $hostname.$domain on $system',
            details: lines.join('\n'));
      } else {
        print('Certificate acquired.');
      }
    });
  }

  String _createDir(String dir) {
    if (!exists(dir)) {
      createDir(dir, recursive: true);
    }
    return dir;
  }

  /// The cloudflare api provider requires an ini style file with the
  /// settings.
  /// This method creates that file.
  void _createSettings() {
    _createDir(dirname(_settings));

    // Only works with a cloudflare global api token.
    _settings.write('dns_cloudflare_api_key=${envToken}');
    _settings.append('dns_cloudflare_email=${envEmailAddress}');

    'chmod 600 $_settings'.run;

    var logfile = Environment().logfile;

    logfile.append('Created certbot settings.ini: ');
    logfile.append(read(_settings).toList().join('\n'));
  }

  // void deleteSettings() {
  //   delete(_settings);
  // }

  @override
  bool get supportsPrivateMode => true;

  @override
  bool get supportsWildCards => true;

  @override
  void dumpEnvironmentVariables() {
    printEnv(AuthProvider.AUTH_PROVIDER_TOKEN, envToken);
    printEnv(AuthProvider.AUTH_PROVIDER_EMAIL_ADDRESS, envEmailAddress);
  }
}
