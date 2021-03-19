@Timeout(Duration(minutes: 30))
import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  test('dockerLog', () async {
    var complete = Completer<void>();

    var linesSeen = 0;

    var logger = DockerLogsInIsolate();

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
    var complete = Completer<void>();

    var containerid = findDockerContainer();

    var lines = 'docker logs --tail 1000 $containerid'.toList().length;

    var linesSeen = 0;
    var logger = DockerLogs(findDockerContainer(), lines, follow: true);
    logger.start().listen((event) {
      print('test: ${linesSeen + 1} $event');

      linesSeen++;
      if (linesSeen == lines - 1) {
        logger.stop();
        complete.complete();
      }
    }, onDone: () {
      logger.stop();
      complete.complete();
    });

    await complete.future;
  });
}

String findDockerContainer() {
  /// find a random docker container to tail.
  var containers = 'docker container ls'.toList(skipLines: 1);
  if (containers.isEmpty) {
    throw ('No containers available to tail');
  }

  /// extract container id.
  return containers[0].split(' ')[0];
}
