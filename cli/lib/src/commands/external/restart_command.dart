import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';

/// Starts nginx and the certbot scheduler.
class RestartCommand extends Command<void> {
  @override
  String get description =>
      'starts the ngix server after it has been started at least once';

  @override
  String get name => 'restart';

  RestartCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information');
  }

  @override
  void run() {
    print('nginx-le container is starting.');

    var debug = argResults['debug'] as bool;
    debug ??= false;

    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    print('Restarting nginx fqdn=${config.fqdn} mode=${config.mode}');

    'docker restart ${config.containerid}'.run;
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}
