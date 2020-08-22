import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Displays the list of active certificates.
void certificates(List<String> args) {
  print('Certificates command running');

  var parser = ArgParser();
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );
  var results = parser.parse(args);
  var debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  var certificates = Certbot().certificates();

  for (var certificate in certificates) {
    print(certificate);
  }
}
