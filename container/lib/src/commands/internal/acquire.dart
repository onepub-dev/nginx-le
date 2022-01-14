import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../util/acquisition_manager.dart';

void acquire(List<String> args) {
  final parser = ArgParser()
    ..addFlag(
      'debug',
      negatable: false,
    );

  final results = parser.parse(args);

  final debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  /// these are used by the certbot auth and clenaup hooks.
  verbose(() => '${Environment().hostnameKey}:${Environment().hostname}');

  verbose(() => '${Environment().domainKey}:${Environment().domain}');
  Settings()
      .verbose('${Environment().productionKey}:${Environment().production}');
  verbose(() =>
      '${Environment().domainWildcardKey}:${Environment().domainWildcard}');
  verbose(
      () => '${Environment().authProviderKey}:${Environment().authProvider}');

  /// if auto acquisition has been blocked a manual call to acquire will
  ///  clear the flag.
  Certbot().clearBlockFlag();

  Certbot().deleteInvalidCertificates(
      hostname: Environment().hostname!,
      domain: Environment().domain!,
      wildcard: Environment().domainWildcard,
      production: Environment().production);

  AuthProviders().getByName(Environment().authProvider!)!.acquire();

  if (Certbot().deployCertificate()) {
    AcquisitionManager().leaveAcquistionMode(reload: true);
  } else {
    AcquisitionManager().enterAcquisitionMode(reload: true);
  }
}
