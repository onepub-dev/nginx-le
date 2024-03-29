@Timeout(Duration(minutes: 10))
library;

/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';

import 'package:async/async.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/tail/tail.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  test('Log - simple no tail', () async {
    const log = '/tmp/nginx/access.log';

    if (!exists(dirname(log))) {
      createDir(dirname(log), recursive: true);
    }
    touch(join(log), create: true);

    log
      ..write('Line 1/4 of log')
      ..append('Line 2/4 of log')
      ..append('Line 3/4 of log')
      ..append('Last line of log');

    final tail = Tail('/tmp/nginx/access.log', 100);
    final stream = await tail.start();

    final finished = Completer<void>();

    stream.listen((line) {
      print('tail: $line');
    }).onDone(() {
      print('done');
      finished.complete();
    });

    await finished.future;
  });

  test('Log - simple  tail', () async {
    const log = '/tmp/nginx/access.log';

    if (!exists(dirname(log))) {
      createDir(dirname(log), recursive: true);
    }
    touch(join(log), create: true);

    log
      ..write('Line 1/4 of log')
      ..append('Line 2/4 of log')
      ..append('Line 3/4 of log')
      ..append('Last line of log');

    final tail = Tail('/tmp/nginx/access.log', 100, follow: true);
    final stream = await tail.start();

    final finished = Completer<void>();

    stream.listen((line) {
      print('tail: $line');

      if (line!.endsWith('9')) {
        tail.stop();
      }
    }).onDone(() {
      print('done');
      finished.complete();
    });

    for (var i = 0; i < 10; i++) {
      log.append('New line $i');
      sleep(2);
    }

    await finished.future;
  });
  test('StreamGroup', () async {
    final syslog = Tail('/var/log/syslog', 10);
    final dmesg = Tail('/var/log/dmesg', 10);
    touch('$HOME/testlog', create: true);
    final testlog = Tail('$HOME/testlog', 10);

    final group = StreamGroup<String>();

    await group.add((await syslog.start()).map((line) => 'syslog: $line'));
    await group.add((await dmesg.start()).map((line) => 'dmsg: $line'));
    await group.add((await testlog.start()).map((line) => 'testlog: $line'));

    unawaited(group.close());
    final finished = Completer<void>();
    group.stream.listen(print).onDone(() {
      print('done');

      finished.complete();
    });

    Future<void>.delayed(const Duration(seconds: 30), () {
      syslog.stop();
      dmesg.stop();
    });

    await finished.future;
  });

  test('StreamGroup - with follow', () async {
    final syslog = Tail('/var/log/syslog', 10, follow: true);
    final dmesg = Tail('/var/log/dmesg', 10, follow: true);
    touch('$HOME/testlog', create: true);
    final testlog = Tail('$HOME/testlog', 10, follow: true);

    final group = StreamGroup<String>();

    await group.add((await syslog.start()).map((line) => 'syslog: $line'));
    await group.add((await dmesg.start()).map((line) => 'dmsg: $line'));
    await group.add((await testlog.start()).map((line) => 'testlog: $line'));

    unawaited(group.close());
    final finished = Completer<void>();
    group.stream.listen(print).onDone(() {
      print('done');

      finished.complete();
    });

    Future<void>.delayed(const Duration(seconds: 10), () {
      syslog.stop();
      dmesg.stop();
      testlog.stop();
    });

    await finished.future;
  });
}
