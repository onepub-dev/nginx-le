@Timeout(Duration(minutes: 30))
import 'dart:async';

import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:test/test.dart';

void main() {
  test('dockerLog', () async {
    var complete = Completer<void>();
    DockerLogsInIsolate().dockerLog('be4d6307ffbf', follow: true).listen((event) {
      print(event);
    });

    await complete.future;
  });

  test('DockerLogs.start', () async {
    var complete = Completer<void>();
    DockerLogs('be4d6307ffbf', 100, follow: true).start().listen((event) {
      print(event);
    });

    await complete.future;
  });
}
