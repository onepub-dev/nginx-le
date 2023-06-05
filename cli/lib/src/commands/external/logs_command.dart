/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class LogsCommand extends Command<void> {
  LogsCommand() {
    // argParser.addOption('containerid',
    //     abbr: 'c',
    //     help:
    //         'The docker containerid to attach to in the form
    //    -containerid="XXXXX"');
    // argParser.addOption('name',
    //     abbr: 'n', help: 'The name of the docker container to attach to');
    argParser
      ..addFlag(
        'nginx',
        abbr: 'x',
        defaultsTo: true,
        help: 'The nginx console output is included.',
      )
      ..addFlag(
        'certbot',
        abbr: 'b',
        help: 'The certbot logs are included.',
      )
      ..addFlag(
        'access',
        abbr: 'a',
        help: 'The nginx access logs are included.',
      )
      ..addFlag(
        'error',
        abbr: 'e',
        help: 'The nginx error logs are included.',
      )
      ..addFlag(
        'follow',
        abbr: 'f',
        defaultsTo: true,
        help: 'Follows the selected log files."',
      )
      ..addOption(
        'lines',
        abbr: 'l',
        defaultsTo: '100',
        help: "Displays the last 'n' lines.",
      )
      ..addFlag('debug', negatable: false);
  }
  @override
  String get description => 'Tails the log file';

  @override
  String get name => 'logs';

  @override
  Future<void> run() async {
    final follow = argResults!['follow'] as bool;
    final lines = argResults!['lines'] as String;
    final certbot = argResults!['certbot'] as bool;
    final nginx = argResults!['nginx'] as bool;
    final access = argResults!['access'] as bool;
    final error = argResults!['error'] as bool;
    final debug = argResults!['debug'] as bool;

    Settings().setVerbose(enabled: debug);

    final config = ConfigYaml()..validate(() => showUsage(argParser));

    var lineCount = 0;
    final _lineCount = int.tryParse(lines);
    if (_lineCount == null) {
      printerr("'lines' must by an integer: found $lines");
      showUsage(argParser);
    } else {
      lineCount = _lineCount;
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

    if (Strings.isEmpty(config.containerid)) {
      printerr('The configured containerid is empty');
      return;
    }
    final containerid = config.containerid!;

    final container = Containers().findByContainerId(containerid);
    if (container == null || !container.isRunning) {
      printerr(red("Nginx-LE container $containerid isn't running. "
          "Use 'nginx-le start' to start the container"));
      exit(1);
    }

    print('Logging Nginx-LE follow=$follow lines=$lineCount certbot=$certbot '
        'nginx=$nginx error=$error access=$access');

    await tailLogs(
        containerid: containerid,
        follow: follow,
        lines: lineCount,
        nginx: nginx,
        certbot: certbot,
        access: access,
        error: error,
        debug: debug);
  }

  Future<void> tailLogs({
    required bool follow,
    required bool nginx,
    required bool certbot,
    required bool debug,
    required bool error,
    required bool access,
    String? containerid,
    int lines = 0,
  }) async {
    // var docker_cmd = 'docker exec -it ${containerid} /home/bin/logs';
    // if (follow) docker_cmd += ' --follow';
    // docker_cmd += ' --lines $lines';
    // if (certbot) docker_cmd += ' --certbot';
    // if (access) docker_cmd += ' --access';
    // if (error) docker_cmd += ' --error';
    // if (debug) docker_cmd += ' --debug';

    if (nginx && (certbot || access || error)) {
      if (argResults!.wasParsed('nginx')) {
        printerr(red('You cannot combine nginx with any other log file'));
        exit(1);
      } else {
        /// it was here by default so just turn it off.
        // ignore: parameter_assignments
        nginx = false;
      }
    }
    try {
      if (certbot || access || error) {
        logInternals(
            containerid: containerid,
            follow: follow,
            lines: lines,
            certbot: certbot,
            access: access,
            error: error,
            debug: debug);
      }

      if (nginx) {
        await logNginx(containerid!, lines, follow: follow);
      }
    } on TailCliException catch (error) {
      printerr(error.message);
      exit(1);
    } on DockerLogsException catch (error) {
      printerr(error.message);
      exit(1);
    }
  }

  void logInternals({
    required bool follow,
    required bool certbot,
    required bool access,
    required bool error,
    required bool debug,
    String? containerid,
    int? lines,
  }) {
    var cmd = 'docker exec -it $containerid /home/bin/logs';
    if (follow) {
      cmd += ' --follow';
    }
    cmd += ' --lines $lines';
    if (certbot) {
      cmd += ' --certbot';
    }
    if (access) {
      cmd += ' --access';
    }
    if (error) {
      cmd += ' --error';
    }
    if (debug) {
      cmd += ' --debug';
    }

    cmd.run;
  }

  Future<void> logNginx(String containerid, int lines,
      {bool follow = false}) async {
    final stream =
        (await DockerLogs(containerid, lines, follow: follow).start())
            .map((line) => 'nginx: $line');

    // pre-close the group as onDone won't be called until the group is closed.
    final finished = Completer<void>();
    stream.listen(print).onDone(() {
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
