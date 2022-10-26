/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Tails selected logs to the console.
void logs(List<String> args) {
  final argParser = ArgParser()
    ..addFlag(
      'follow',
      abbr: 'f',
      negatable: false,
      help: 'If set, we follow the specified logs.',
    )
    ..addOption(
      'lines',
      abbr: 'n',
      defaultsTo: '100',
      help: "Displays the last 'n' lines.",
    )

    // default log files
    ..addFlag(
      'certbot',
      abbr: 'c',
      defaultsTo: true,
      negatable: false,
      help: 'The certbot logs are included.',
    )
    ..addFlag('error',
        abbr: 'e',
        defaultsTo: true,
        negatable: false,
        help: 'The nginx error logs are included.')

    // optional log files
    ..addFlag('access',
        abbr: 'a',
        negatable: false,
        help: 'The nginx logs access logs are included.')
    ..addFlag(
      'debug',
      negatable: false,
    );
  late ArgResults results;
  try {
    results = argParser.parse(args);
  } on FormatException catch (e) {
    printerr(e.message);
    showUsage(argParser);
  }
  final debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);

  final follow = results['follow'] as bool;
  final lines = results['lines'] as String;
  final certbot = results['certbot'] as bool;
  final access = results['access'] as bool;
  final error = results['error'] as bool;

  late final int lineCount;
  int? _lineCount;
  if ((_lineCount = int.tryParse(lines)) == null) {
    printerr("'lines' must by an integer: found $lines");
    showUsage(argParser);
  }
  lineCount = _lineCount!;

  final group = StreamGroup<String>();

  var usedefaults = true;

  /// If the user explicitly sets a logfile then we ignore all of
  /// the default logfiles.
  if (results.wasParsed('certbot') ||
      results.wasParsed('access') ||
      results.wasParsed('error')) {
    usedefaults = false;
  }

  try {
    if (certbot && (usedefaults || results.wasParsed('certbot'))) {
      unawaited(group.add(Tail(Certbot().logfile, lineCount, follow: follow)
          .start()
          .map((line) => 'certbot: $line')));
    }

    if (access && (usedefaults || results.wasParsed('access'))) {
      unawaited(group.add(Tail(Nginx.accesslogpath, lineCount, follow: follow)
          .start()
          .map((line) => 'access: $line')));
    }

    if (error && (usedefaults || results.wasParsed('error'))) {
      unawaited(group.add(Tail(Nginx.errorlogpath, lineCount, follow: follow)
          .start()
          .map((line) => 'error: $line')));
    }
  } on TailException catch (error) {
    printerr(error.message);
    exit(1);
  }

  unawaited(group.close());

  final finished = Completer<void>();
  group.stream.listen(print).onDone(() {
    print('waitForDone - completing');
    print('done');

    finished.complete();
  });

  verbose(() => 'waitForDone - group close start');
  // ignore: discarded_futures
  waitForEx<void>(group.close());
  verbose(() => 'waitForDone - group close end');
  // Future<void>.delayed(Duration(seconds: 30), () {
  //   syslog.stop();
  //   dmesg.stop();
  // });
  verbose(() => 'waitForDone -start');
  waitForEx<void>(finished.future);
  verbose(() => 'waitForDone -end');
}

void showUsage(ArgParser parser) {
  print(parser.usage);

  print('If you explictly specify any log file then the default '
      'set of log files is ignored');
  exit(-1);
}
