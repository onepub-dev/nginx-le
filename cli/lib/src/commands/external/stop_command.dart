import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:strings/strings.dart';

class StopCommand extends Command<void> {
  StopCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information.');
  }

  @override
  String get description => 'Stops the Nginx-LE container';

  @override
  String get name => 'stop';

  @override
  void run() {
    final config = ConfigYaml()..validate(() => showUsage(argParser));

    if (Strings.isEmpty(config.containerid)) {
      printerr('The configured containerid is empty');
      return;
    }
    final containerid = config.containerid!;
    final container = Containers().findByContainerId(containerid);
    if (container != null && container.isRunning) {
      print('Stopping...');
      container.stop();
    } else {
      printerr('The container $containerid is not running');
    }
  }

  void showUsage(ArgParser parser) {
    print('');
    print('Stops the nginx-le container');
    print(parser.usage);
    exit(1);
  }
}
