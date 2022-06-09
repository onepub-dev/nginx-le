/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


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
