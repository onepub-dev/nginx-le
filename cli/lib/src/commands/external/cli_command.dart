import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class CliCommand extends Command<void> {
  @override
  String get description =>
      'Starts a bash shell allowing you to interact with the container.';

  @override
  String get name => 'cli';

  CliCommand() {
    argParser.addFlag(
      'debug',
      abbr: 'd',
      defaultsTo: false,
      negatable: false,
      help: 'Outputs additional logging information',
    );
  }

  @override
  void run() {
    var debug = argResults['debug'] as bool;
    Settings().setVerbose(enabled: debug);
    var config = ConfigYaml();

    config.validate(() => showUsage(argParser));

    var container = Containers().findByContainerId(config.containerid);
    if (container.isRunning) {
      'docker exec -it ${config.containerid} /bin/bash'
          .start(nothrow: true, terminal: true);
    } else {
      printerr(
          'The container ${config.containerid} is not running. You need to start it first.');
    }
  }
}
