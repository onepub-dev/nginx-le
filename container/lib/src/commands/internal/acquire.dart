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
  Settings().verbose('${Environment().hostnameKey}:${Environment().hostname}');

  Settings().verbose('${Environment().domainKey}:${Environment().domain}');
  Settings().verbose('${Environment().productionKey}:${Environment().production}');
  Settings().verbose('${Environment().domainWildcardKey}:${Environment().domainWildcard}');
  Settings().verbose('${Environment().authProviderKey}:${Environment().authProvider}');

  /// if auto acquisition has been block an manual call to acquistion will clear the flag.
  Certbot().clearBlockFlag;

  var authProvider = AuthProviders().getByName(Environment().authProvider);
  authProvider.acquire();

  Certbot().deployCertificates(
      hostname: Environment().hostname,
      domain: Environment().domain,
      wildcard: Environment().domainWildcard,
      autoAcquireMode: Environment().autoAcquire);
}
