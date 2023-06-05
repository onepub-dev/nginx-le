@Timeout(Duration(minutes: 30))
library;

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  test('dockerLog', () async {
    final complete = Completer<void>();

    var linesSeen = 0;

    final logger = DockerLogsInIsolate();

    logger.dockerLog(findDockerContainer(), follow: true).listen((event) {
      print(event);
      linesSeen++;
      if (linesSeen == 10) {
        logger.stop();
        complete.complete();
      }
    });

    await complete.future;
  });

  test('DockerLogs.start', () async {
    final complete = Completer<void>();

    final containerid = findDockerContainer();

    final lines = 'docker logs --tail 1000 $containerid'.toList().length;

    var linesSeen = 0;
    final logger = DockerLogs(findDockerContainer(), lines, follow: true);
    (await logger.start()).listen((event) {
      print('test: ${linesSeen + 1} $event');

      linesSeen++;
      if (linesSeen == lines - 1) {
        logger.stop();
        complete.complete();
      }
    }, onDone: () {
      logger.stop();
      if (!complete.isCompleted) {
        complete.complete();
      }
    });

    await complete.future;
  });
}

String findDockerContainer() {
  /// find a random docker container to tail.
  final containers = 'docker container ls'.toList(skipLines: 1);
  if (containers.isEmpty) {
    throw Exception('No containers available to tail');
  }

  /// extract container id.
  return containers[0].split(' ')[0];
}
