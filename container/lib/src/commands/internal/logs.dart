import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:async/async.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Tails selected logs to the console.
void logs(List<String> args) {
  var argParser = ArgParser();

  argParser.addFlag(
    'follow',
    abbr: 'f',
    defaultsTo: true,
    negatable: false,
    help: 'If set we follow the specified logs.',
  );
  argParser.addOption(
    'lines',
    abbr: 'n',
    defaultsTo: '100',
    help: "Displays the last 'n' lines.",
  );

  // default log files
  argParser.addFlag(
    'certbot',
    abbr: 'c',
    defaultsTo: true,
    negatable: false,
    help: 'The certbot logs are included.',
  );

  argParser.addFlag('error',
      abbr: 'e',
      defaultsTo: true,
      negatable: false,
      help: 'The nginx error logs are included.');

  // optional log files
  argParser.addFlag('access',
      abbr: 'a',
      defaultsTo: false,
      negatable: false,
      help: 'The nginx logs access logs are included.');

  argParser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );
  var results = argParser.parse(args);
  var debug = results['debug'] as bool;

  Settings().setVerbose(enabled: debug);

  var follow = results['follow'] as bool;
  var lines = results['lines'] as String;
  var certbot = results['certbot'] as bool;
  var access = results['access'] as bool;
  var error = results['error'] as bool;

  var lineCount = 0;
  if ((lineCount = int.tryParse(lines)) == null) {
    printerr("'lines' must by an integer: found $lines");
    showUsage(argParser);
  }

  var group = StreamGroup<String>();

  var usedefaults = true;

  /// If the user explicitly sets a logfile then we ignore all of the default logfiles.
  if (results.wasParsed('certbot') ||
      results.wasParsed('access') ||
      results.wasParsed('error')) {
    usedefaults = false;
  }

  try {
    if (certbot && (usedefaults || results.wasParsed('certbot'))) {
      group.add(Tail(Certbot().logfile, lineCount, follow: follow)
          .start()
          .map((line) => 'certbot: $line'));
    }

    if (access && (usedefaults || results.wasParsed('access'))) {
      group.add(Tail(Nginx.accesslogpath, lineCount, follow: follow)
          .start()
          .map((line) => 'access: $line'));
    }

    if (error && (usedefaults || results.wasParsed('error'))) {
      group.add(Tail(Nginx.errorlogpath, lineCount, follow: follow)
          .start()
          .map((line) => 'error: $line'));
    }
  } on TailException catch (error) {
    printerr(error.message);
    exit(1);
  }

  // pre-close the group as onDone won't be called until the group is closed.
  group.close();

  var finished = Completer<void>();
  group.stream.listen((line) => print(line)).onDone(() {
    print('done');

    finished.complete();
  });

  // Future<void>.delayed(Duration(seconds: 30), () {
  //   syslog.stop();
  //   dmesg.stop();
  // });

  waitForEx<void>(finished.future);
}

void showUsage(ArgParser parser) {
  print(parser.usage);

  print(
      'If you explictly specify any log file then the default set of log files is ignored');
  exit(-1);
}
