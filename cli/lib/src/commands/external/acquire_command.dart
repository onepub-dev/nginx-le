/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:strings/strings.dart';

import 'util.dart';

class AcquireCommand extends Command<void> {
  AcquireCommand() {
    argParser.addFlag(
      'debug',
      abbr: 'd',
      negatable: false,
      help: 'Outputs additional logging information',
    );
  }
  @override
  String get description =>
      'Obtains or forces the renewal of a lets encrypt certificate';

  @override
  String get name => 'acquire';

  @override
  void run() {
    final debug = argResults!['debug'] as bool;

    Settings().setVerbose(enabled: debug);
    Environment().certbotVerbose = debug;

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    if (Strings.isEmpty(config.containerid)) {
      printerr('The config.containerid is empty');
      return;
    }

    final containerid = config.containerid!;

    final container = Containers().findByContainerId(containerid);
    if (container == null) {
      printerr("Can't find container with id: $containerid");
      return;
    }

    if (container.isRunning) {
      var cmd = 'docker exec -it $containerid /home/bin/acquire ';

      print('');
      print(orange(
          'Please be patient this can take a quite a few minutes to complete'));

      if (debug == true) {
        cmd += ' --debug';
      }
      cmd.run;
    } else {
      printerr(red("The Nginx-LE container $containerid isn't running. "
          "Use 'nginx-le start' to start the container"));
    }
  }
}
