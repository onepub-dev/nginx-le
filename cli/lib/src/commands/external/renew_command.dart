/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class RenewCommand extends Command<void> {
  RenewCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form
    // --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information');
  }

  @override
  String get description =>
      'Runs a renew on the certificate. This should normally be unnecessary '
      'as renewal checks are schedule every 13 hours';

  @override
  String get name => 'renew';
  @override
  void run() {
    print('Renew command running');

    final debug = argResults!['debug'] as bool;

    ///var target = containerOrName(argParser, argResults);
    ///
    final config = ConfigYaml()..validate(() => showUsage(argParser));

    var cmd = 'docker exec -it ${config.containerid} /home/bin/renew';
    if (debug) {
      cmd += ' --debug';
    }
    cmd.run;
  }
}
