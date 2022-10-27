/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class CliCommand extends Command<void> {
  CliCommand() {
    argParser.addFlag(
      'debug',
      abbr: 'd',
      negatable: false,
      help: 'Outputs additional logging information',
    );
  }
  @override
  String get description =>
      'Starts a bash shell allowing you to interact with the container.';

  @override
  String get name => 'cli';

  @override
  void run() {
    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);
    final config = ConfigYaml()..validate(() => showUsage(argParser));

    if (Strings.isEmpty(config.containerid)) {
      printerr('The configured containerid is empty');
      return;
    }
    final containerid = config.containerid!;

    final container = Containers().findByContainerId(containerid);
    if (container != null && container.isRunning) {
      'docker exec -it $containerid /bin/bash'
          .start(nothrow: true, terminal: true);
    } else {
      printerr('The container $containerid is not running. '
          'You need to start it first.');
    }
  }
}
