import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_cli/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class RevokeCommand extends Command<void> {
  @override
  String get description =>
      'Revokes the active Lets Encrypt certificate and places the server into acquire mode.';

  @override
  String get name => 'revoke';

  RevokeCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag('debug',
        abbr: 'd',
        defaultsTo: false,
        negatable: false,
        help: 'Outputs additional logging information');
    // argParser.addFlag('staging',
    //     abbr: 's',
    //     defaultsTo: false,
    //     help: 'Revokes a staging (test) certificate');
  }

  @override
  void run() {
    //var staging = argResults['staging'] as bool;
    var debug = argResults['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    //var target = containerOrName(argParser, argResults);

    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    if (Containers().findByContainerId(config.containerid).isRunning) {
      var cmd = 'docker exec -it ${config.containerid} /home/bin/revoke';
      if (config.isStaging) cmd += ' --staging';
      if (debug) cmd += ' --debug';
      cmd.run;
    } else {
      printerr(red(
          "The Nginx-LE container ${config.containerid} isn't running. Use 'nginx-le start' to start the container"));
    }
  }
}