import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class StopCommand extends Command<void> {
  @override
  String get description => 'Stops the Nginx-LE container';

  @override
  String get name => 'stop';

  StopCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag('debug', abbr: 'd', negatable: false, help: 'Outputs additional logging information');
  }

  @override
  void run() {
    var config = ConfigYaml();

    config.validate(() => showUsage(argParser));

    //var target = containerOrName(argParser, argResults);

    var container = Containers().findByContainerId(config.containerid);
    if (container.isRunning) {
      print('Stopping...');
      container.stop();
    } else {
      printerr('The container ${config.containerid} is not running');
    }
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
  }
}
