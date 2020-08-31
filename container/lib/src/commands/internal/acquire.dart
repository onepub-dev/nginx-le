import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

void acquire(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );

  var results = parser.parse(args);

  var debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  /// these are used by the certbot auth and clenaup hooks.
  Settings().verbose('HOSTNAME:${Environment().hostname}');

  Settings().verbose('DOMAIN:${Environment().domain}');
  Settings().verbose('MODE:${Environment().mode}');
  Settings().verbose('STAGING:${Environment().staging}');
  Settings().verbose('DOMAIN_WILDCARD:${Environment().wildcard}');
  Settings().verbose('AuthProvider:${Environment().certbotAuthProvider}');

  var certbotAuthProvider =
      AuthProviders().getByName(Environment().certbotAuthProvider);
  certbotAuthProvider.acquire();

  Certbot().deployCertificates(
      hostname: Environment().hostname,
      domain: Environment().domain,
      autoAcquireMode: Environment().autoAcquire);
}
