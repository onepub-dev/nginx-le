import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// revokes any existing certificates by deleting
/// the contents of the letsencrypt directory and setting
/// the server into acquire mode.
void revoke(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );

  var results = parser.parse(args);
  var debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);
  Settings().verbose('${Environment().hostnameKey}:${Environment().hostname}');
  Settings().verbose('${Environment().domainKey}:${Environment().domain}');

  Certbot.revokeAll();

  /// delete all of the certificates
  // find('*', root: _latestCertificatePath(hostname, domain))
  //     .forEach((file) => delete(file));
  /// calling deploy will put nginx back into acquire mode.
  Certbot().deployCertificates(
      hostname: Environment().hostname,
      domain: Environment().domain,
      revoking: true,
      wildcard: Environment().domainWildcard,
      autoAcquireMode: Environment().autoAcquire);
}
