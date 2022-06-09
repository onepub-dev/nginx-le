/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../util/acquisition_manager.dart';

/// revokes any existing certificates by deleting
/// the contents of the letsencrypt directory and setting
/// the server into acquire mode.
void revoke(List<String> args) {
  final parser = ArgParser()
    ..addFlag(
      'debug',
      negatable: false,
    );

  final results = parser.parse(args);
  final debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);
  verbose(() => '${Environment.hostnameKey}:${Environment().hostname}');
  verbose(() => '${Environment.domainKey}:${Environment().domain}');

  Certbot().revokeAll();
  AcquisitionManager().enterAcquisitionMode(reload: true);
}
