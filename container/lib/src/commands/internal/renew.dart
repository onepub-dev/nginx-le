import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// revokes any existing certificates by deleting
/// the contents of the letsencrypt directory and setting
/// the server into acquire mode.
void renew(List<String> args) {
  print('Renew command running');

  final parser = ArgParser()
    ..addFlag(
      'debug',
      negatable: false,
    )
    ..addFlag(
      'force',
      help: 'Forces a renewal of the certificates even if it '
          "isn't ready to expire",
      negatable: false,
    );
  final results = parser.parse(args);
  final debug = results['debug'] as bool;
  final force = results['force'] as bool;

  Settings().setVerbose(enabled: debug);

  Certbot().renew(force: force);
}
