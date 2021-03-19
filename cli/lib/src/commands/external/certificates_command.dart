import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class CertificatesCommand extends Command<void> {
  @override
  String get description => 'Prints a list of the active certificates.';

  @override
  String get name => 'certificates';

  CertificatesCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        defaultsTo: false,
        negatable: false,
        help: 'Outputs additional logging information');
  }

  @override
  void run() {
    var debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    var container = Containers().findByContainerId(config.containerid)!;
    if (container.isRunning) {
      'docker exec -it ${config.containerid} /home/bin/certificates ${config.domain}'
          .run;
    } else {
      printerr(
          'The container ${config.containerid} is not running. You need to start it first.');
    }
  }
}
