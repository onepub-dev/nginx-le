import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../../../nginx_le_shared.dart';
import '../generic_auth_provider.dart';
import 'dns_auth_hook.dart';
import 'dns_cleanup_hook.dart';

class NameCheapAuthProvider extends GenericAuthProvider {
  /// Name Cheap settings
  static const NAMECHEAP_API_KEY = 'apiKey';
  static const NAMECHEAP_API_USERNAME = 'apiUsername';

  @override
  String get name => 'namecheap';

  @override
  String get summary => 'Namecheap DNS';

  @override
  void promptForSettings(ConfigYaml config) {
    var namecheap_username = ask(
      'NameCheap API Username:',
      defaultValue: apiUsername,
      validator: Ask.required,
    );
    apiUsername = namecheap_username;

    var namecheap_apikey = ask(
      'NameCheap API Key:',
      defaultValue: apiKey,
      hidden: true,
      validator: Ask.required,
    );
    apiKey = namecheap_apikey;
  }

  @override
  void pre_auth() {
    ArgumentError.checkNotNull(Environment().namecheapApiKey, 'Environment variable: NAMECHEAP_API_KEY missing');
    ArgumentError.checkNotNull(Environment().namecheapApiUser, 'Environment variable: NAMECHEAP_API_USER missing');
  }

  @override
  void auth_hook() {
    namecheap_dns_auth_hook();
  }

  @override
  void cleanup_hook() {
    namncheap_dns_cleanup_hook();
  }

  @override
  List<EnvVar> get environment {
    var vars = <EnvVar>[];

    vars.add(EnvVar(NAMECHEAP_API_KEY, apiKey));
    vars.add(EnvVar(NAMECHEAP_API_USERNAME, apiUsername));

    return vars;
  }

  set apiKey(String namecheap_apikey) => ConfigYaml().settings[_apiKeySetting] = namecheap_apikey;
  String get apiKey => ConfigYaml().settings[_apiKeySetting] as String;
  set apiUsername(String namecheap_apiusername) => ConfigYaml().settings[_apiUsernameSetting] = namecheap_apiusername;
  String get apiUsername => ConfigYaml().settings[_apiUsernameSetting] as String;

  String get _apiKeySetting => 'namecheap_apikey';
  String get _apiUsernameSetting => 'namecheap_apiusername';
}
