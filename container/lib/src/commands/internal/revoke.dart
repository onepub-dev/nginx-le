import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/util/acquisition_manager.dart';
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
  verbose(() => '${Environment().hostnameKey}:${Environment().hostname}');
  verbose(() => '${Environment().domainKey}:${Environment().domain}');

  Certbot().revokeAll();

  if (Certbot().deployCertificate()) {
    AcquisitionManager().leaveAcquistionMode(reload: true);
  } else {
    AcquisitionManager().enterAcquisitionMode(reload: true);
  }
}
