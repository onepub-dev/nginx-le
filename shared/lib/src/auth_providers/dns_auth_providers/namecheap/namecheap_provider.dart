import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../../../nginx_le_shared.dart';
import '../generic_auth_provider.dart';
import 'dns_auth_hook.dart';
import 'dns_cleanup_hook.dart';

class NameCheapAuthProvider extends GenericAuthProvider {
  @override
  String get name => 'namecheap';

  @override
  String get summary => 'Namecheap DNS Auth Provider';

  @override
  void promptForSettings(ConfigYaml config) {
    configUsername = ask(
      'NameCheap API Username:',
      defaultValue: configUsername,
      validator: Ask.required,
    );

    configToken = ask(
      'NameCheap API Key:',
      defaultValue: configToken,
      hidden: true,
      validator: Ask.required,
    );
  }

  @override
  void pre_auth() {
    ArgumentError.checkNotNull(
        envToken, 'Environment variable: AUTH_PROVIDER_TOKEN missing');
    ArgumentError.checkNotNull(
        envUsername, 'Environment variable: AUTH_PROVIDER_USERNAME missing');
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

    vars.add(EnvVar(AuthProvider.AUTH_PROVIDER_TOKEN, configToken));
    vars.add(EnvVar(AuthProvider.AUTH_PROVIDER_USERNAME, configUsername));

    return vars;
  }

  @override
  bool get supportsPrivateMode => true;

  @override
  bool get supportsWildCards => true;
}
