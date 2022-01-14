import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Displays the list of active certificates.
void certificates(List<String> args) {
  print('Certificates command running');

  final parser = ArgParser()
    ..addFlag(
      'debug',
      negatable: false,
    );
  final results = parser.parse(args);
  final debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  Certbot().certificates().forEach(print);
}
