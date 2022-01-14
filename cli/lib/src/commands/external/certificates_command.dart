import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'util.dart';

class CertificatesCommand extends Command<void> {
  CertificatesCommand() {
    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional logging information');
  }
  @override
  String get description => 'Prints a list of the active certificates.';

  @override
  String get name => 'certificates';

  @override
  void run() {
    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    final container = Containers().findByContainerId(config.containerid ?? '')!;
    if (container.isRunning) {
      'docker exec -it ${config.containerid} /home/bin/certificates ${config.domain}'
          .run;
    } else {
      printerr('The container ${config.containerid} is not running. '
          'You need to start it first.');
    }
  }
}
