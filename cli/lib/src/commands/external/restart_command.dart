/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class RestartCommand extends Command<void> {
  RestartCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information');
  }
  @override
  String get description =>
      're-starts the ngix server after it has been started at least once';

  @override
  String get name => 'restart';

  @override
  void run() {
    print('nginx-le container is re-starting.');

    final debug = argResults!['debug'] as bool;

    Settings().setVerbose(enabled: debug);

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    print('Restarting nginx fqdn=${config.fqdn} ');

    'docker restart ${config.containerid}'.run;
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}
