import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/util/acquisition_manager.dart';
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
  Settings()
      .verbose('${Environment().productionKey}:${Environment().production}');
  Settings().verbose(
      '${Environment().domainWildcardKey}:${Environment().domainWildcard}');
  Settings().verbose(
      '${Environment().authProviderKey}:${Environment().authProvider}');

  /// if auto acquisition has been blocked a manual call to acquire will clear the flag.
  Certbot().clearBlockFlag;

  var authProvider = AuthProviders().getByName(Environment().authProvider);
  authProvider.acquire();

  if (Certbot().deployCertificates()) {
    AcquisitionManager.leaveAcquistionMode();
  } else {
    AcquisitionManager.enterAcquisitionMode();
  }
}
