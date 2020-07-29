import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class LogsCommand extends Command<void> {
  @override
  String get description => 'Tails the log file';

  @override
  String get name => 'logs';

  LogsCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form --containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser.addFlag(
      'nginx',
      abbr: 'x',
      defaultsTo: true,
      help: 'The nginx console output is included.',
    );
    argParser.addFlag(
      'certbot',
      abbr: 'b',
      defaultsTo: false,
      help: 'The certbot logs are included.',
    );
    argParser.addFlag(
      'access',
      abbr: 'a',
      defaultsTo: false,
      help: 'The nginx access logs are included.',
    );
    argParser.addFlag(
      'error',
      abbr: 'e',
      defaultsTo: false,
      help: 'The nginx error logs are included.',
    );
    argParser.addFlag(
      'follow',
      abbr: 'f',
      defaultsTo: true,
      help: 'Follows the selected log files."',
    );
    argParser.addOption(
      'lines',
      abbr: 'l',
      defaultsTo: '100',
      help: "Displays the last 'n' lines.",
    );

    argParser.addFlag('debug', negatable: false, defaultsTo: false);
  }

  @override
  void run() {
    var follow = argResults['follow'] as bool;
    var lines = argResults['lines'] as String;
    var certbot = argResults['certbot'] as bool;
    var nginx = argResults['nginx'] as bool;
    var access = argResults['access'] as bool;
    var error = argResults['error'] as bool;
    var debug = argResults['debug'] as bool;

    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();
    config.validate(() => showUsage(argParser));

    var lineCount = 0;
    if ((lineCount = int.tryParse(lines)) == null) {
      printerr("'lines' must by an integer: found $lines");
      showUsage(argParser);
    }

    if (lineCount < 0) {
      printerr("'lines' must be >= 0");
      showUsage(argParser);
    }

    if (follow) {
      print('nginx-le tailing logs. Type ctrl-c to stop.');
    } else {
      if (lineCount == 0) {
        printerr("'lines' must be > 0 unless you are tailing the logs.");
        showUsage(argParser);
      }
      print('nginx-le displaying logs. ');
    }

    var container = Containers().findByContainerId(config.containerid);
    if (!container.isRunning) {
      printerr(red(
          "Nginx-LE container ${config.containerid} isn't running. Use 'nginx-le start' to start the container"));
      exit(1);
    }

    print(
        'Logging Nginx-LE follow=$follow lines=$lineCount certbot=$certbot nginx=$nginx error=$error access=$access');

    tailLogs(config.containerid, follow, lineCount, nginx, certbot, access,
        error, debug);
  }

  void tailLogs(String containerid, bool follow, int lines, bool nginx,
      bool certbot, bool access, bool error, bool debug) {
    // var docker_cmd = 'docker exec -it ${containerid} /home/bin/logs';
    // if (follow) docker_cmd += ' --follow';
    // docker_cmd += ' --lines $lines';
    // if (certbot) docker_cmd += ' --certbot';
    // if (access) docker_cmd += ' --access';
    // if (error) docker_cmd += ' --error';
    // if (debug) docker_cmd += ' --debug';

    if (nginx && (certbot || access || error)) {
      if (argResults.wasParsed('nginx')) {
        printerr(red('You cannot combine nginx with any other log file'));
        exit(1);
      } else {
        /// it was here by default so just turn it off.
        nginx = false;
      }
    }
    try {
      if (certbot || access || error) {
        logInternals(containerid, follow, lines, certbot, access, error, debug);
      }

      if (nginx) {
        logNginx(containerid, lines, follow: follow);
      }
    } on TailCliException catch (error) {
      printerr(error.message);
      exit(1);
    } on DockerLogsException catch (error) {
      printerr(error.message);
      exit(1);
    }
  }

  void logInternals(
    String containerid,
    bool follow,
    int lines,
    bool certbot,
    bool access,
    bool error,
    bool debug,
  ) {
    var cmd = 'docker exec -it ${containerid} /home/bin/logs';
    if (follow) cmd += ' --follow';
    cmd += ' --lines $lines';
    if (certbot) cmd += ' --certbot';
    if (access) cmd += ' --access';
    if (error) cmd += ' --error';
    if (debug) cmd += ' --debug';

    cmd.run;
  }

  void logNginx(String containerid, int lines, {bool follow = false}) {
    var stream = DockerLogs(containerid, lines, follow: follow)
        .start()
        .map((line) => 'nginx: $line');

    // pre-close the group as onDone won't be called until the group is closed.
    var finished = Completer<void>();
    stream.listen((line) => print(line)).onDone(() {
      print('done');

      finished.complete();
    });

    waitForEx<void>(finished.future);
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}
