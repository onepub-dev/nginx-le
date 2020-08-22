import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class RevokeCommand extends Command<void> {
  @override
  String get description =>
      'Runs a renew on the certificate. This should normally be necessary as renewal checks a schedule every 13 hours';

  @override
  String get name => 'renew';

  RevokeCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag('debug',
        abbr: 'd', defaultsTo: false, negatable: false, help: 'Outputs additional logging information');
  }

  @override
  void run() {
    print('Renew command running');

    var debug = argResults['debug'] as bool;

    ///var target = containerOrName(argParser, argResults);
    ///
    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    var cmd = 'docker exec -it ${config.containerid} /home/bin/renew';
    if (debug) cmd += ' --debug';
    cmd.run;
  }
}
