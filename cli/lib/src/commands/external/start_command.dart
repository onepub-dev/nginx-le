/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts the nginx-le container.
class StartCommand extends Command<void> {
  StartCommand() {
    argParser
      ..addFlag('debug',
          abbr: 'd',
          negatable: false,
          help: 'Outputs additional logging information')
      ..addFlag('interactive',
          abbr: 'i',
          negatable: false,
          help: 'Starts the container in the foreground so you can '
              'see all output');
  }

  @override
  String get description => 'starts the ngix server';

  @override
  String get name => 'start';

  @override
  void run() {
    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    final interactive = argResults!['interactive'] as bool;

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    final containerid = config.containerid ?? '';
    final container = Containers().findByContainerId(containerid);
    if (container == null) {
      printerr('Unable to find container: ');
      return;
    }

    if (container.isRunning) {
      printerr('The container $containerid is already running. '
          'Consider nginx-le restart');
      showUsage(argParser);
    }

    print('Starting nginx container $containerid');

    container.start(daemon: !interactive);

    sleep(3);

    if (!container.isRunning) {
      printerr(red('The container $containerid failed to start'));
      print(green('Showing docker logs'));
      container.showLogs();
    }
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}
