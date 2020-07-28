import 'package:args/args.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// revokes any existing certificates by deleting
/// the contents of the letsencrypt directory and setting
/// the server into acquire mode.
void renew(List<String> args) {
  print('Renew command running');

  var parser = ArgParser();
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );
  var results = parser.parse(args);
  var debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);

  Certbot().renew();
}
