import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class StopCommand extends Command<void> {
  @override
  String get description => 'Stops the Nginx-LE container';

  @override
  String get name => 'stop';

  StopCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information.');
  }

  @override
  void run() {
    var config = ConfigYaml();

    config.validate(() => showUsage(argParser));

    var container = Containers().findByContainerId(config.containerid);
    if (container.isRunning) {
      print('Stopping...');
      container.stop();
    } else {
      printerr('The container ${config.containerid} is not running');
    }
  }

  void showUsage(ArgParser parser) {
    print('');
    print('Stops the nginx-le container');
    print(parser.usage);
    exit(1);
  }
}
