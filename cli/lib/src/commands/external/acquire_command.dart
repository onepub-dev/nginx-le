import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class AcquireCommand extends Command<void> {
  @override
  String get description => 'Obtains or forces the renewal of a lets encrypt certificate';

  @override
  String get name => 'acquire';

  AcquireCommand() {
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
    Environment().certbotVerbose = debug;

    var config = ConfigYaml();

    config.validate(() => showUsage(argParser));

    if (Containers().findByContainerId(config.containerid).isRunning) {
      var cmd = 'docker exec -it ${config.containerid} /home/bin/acquire ';

      if (config.isModePrivate) {
        print('');
        print(orange('Please be patient this can take a quite a few minutes to complete'));
      }

      if (debug == true) cmd += ' --debug';
      cmd.run;
    } else {
      printerr(red(
          "The Nginx-LE container ${config.containerid} isn't running. Use 'nginx-le start' to start the container"));
    }
  }
}
