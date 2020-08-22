@Timeout(Duration(minutes: 10))
import 'dart:async';

import 'package:async/async.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/src/tail/tail.dart';
import 'package:pedantic/pedantic.dart';
import 'package:test/test.dart';

void main() {
  test('Log - simple no tail', () {
    Settings().setVerbose(enabled: true);

    var log = '/tmp/nginx/access.log';

    if (!exists(dirname(log))) {
      createDir(dirname(log), recursive: true);
    }
    touch(join(log), create: true);

    log.write('Line 1/4 of log');
    log.append('Line 2/4 of log');
    log.append('Line 3/4 of log');
    log.append('Last line of log');

    var tail = Tail('/tmp/nginx/access.log', 100, follow: false);
    var stream = tail.start();

    var finished = Completer<void>();

    stream.listen((line) {
      print('tail: $line');
    }).onDone(() {
      print('done');
      finished.complete();
    });
    ;

    waitForEx<void>(finished.future);
  });

  test('Log - simple  tail', () {
    Settings().setVerbose(enabled: true);

    var log = '/tmp/nginx/access.log';

    if (!exists(dirname(log))) {
      createDir(dirname(log), recursive: true);
    }
    touch(join(log), create: true);

    log.write('Line 1/4 of log');
    log.append('Line 2/4 of log');
    log.append('Line 3/4 of log');
    log.append('Last line of log');

    var tail = Tail('/tmp/nginx/access.log', 100, follow: true);
    var stream = tail.start();

    var finished = Completer<void>();

    stream.listen((line) {
      print('tail: $line');
    }).onDone(() {
      print('done');
      finished.complete();
    });

    for (var i = 0; i < 10; i++) {
      log.append('New line $i');
      sleep(2);
    }

    waitForEx<void>(finished.future);
  });
  test('StreamGroup', () async {
    var syslog = Tail('/var/log/syslog', 10);
    var dmesg = Tail('/var/log/dmesg', 10);
    var testlog = Tail('$HOME/testlog', 10);

    var group = StreamGroup<String>();

    await group.add(syslog.start().map((line) => 'syslog: $line'));
    await group.add(dmesg.start().map((line) => 'dmsg: $line'));
    await group.add(testlog.start().map((line) => 'testlog: $line'));

    unawaited(group.close());
    var finished = Completer<void>();
    group.stream.listen((line) => print(line)).onDone(() {
      print('done');

      finished.complete();
    });

    Future<void>.delayed(Duration(seconds: 30), () {
      syslog.stop();
      dmesg.stop();
    });

    waitForEx<void>(finished.future);
  });

  test('StreamGroup - with follow', () async {
    var syslog = Tail('/var/log/syslog', 10, follow: true);
    var dmesg = Tail('/var/log/dmesg', 10, follow: true);
    var testlog = Tail('$HOME/testlog', 10, follow: true);

    var group = StreamGroup<String>();

    await group.add(syslog.start().map((line) => 'syslog: $line'));
    await group.add(dmesg.start().map((line) => 'dmsg: $line'));
    await group.add(testlog.start().map((line) => 'testlog: $line'));

    unawaited(group.close());
    var finished = Completer<void>();
    group.stream.listen((line) => print(line)).onDone(() {
      print('done');

      finished.complete();
    });

    Future<void>.delayed(Duration(seconds: 30), () {
      syslog.stop();
      dmesg.stop();
    });

    waitForEx<void>(finished.future);
  });
}
