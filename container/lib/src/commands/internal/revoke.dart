import 'package:args/args.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_container/src/internal_run_config.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// revokes any existing certificates by deleting
/// the contents of the letsencrypt directory and setting
/// the server into acquire mode.
void revoke(List<String> args) {
  var config = InternalRunConfig.load();

  var parser = ArgParser();
  parser.addFlag(
    'staging',
    defaultsTo: false,
    negatable: false,
  );
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );

  var results = parser.parse(args);
  var staging = results['staging'] as bool;
  var debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);
  setEnv('HOSTNAME', config.hostname);
  setEnv('DOMAIN', config.domain);

  Certbot().revoke(
      hostname: config.hostname, domain: config.domain, staging: staging);

  /// delete all of the certificates
  // find('*', root: _latestCertificatePath(hostname, domain))
  //     .forEach((file) => delete(file));
  /// calling deploy will put nginx back into acquire mode.
  Certbot().deployCertificates(
      hostname: config.hostname, domain: config.domain, revoking: true);
}
