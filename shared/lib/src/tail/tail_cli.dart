/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dcli/dcli.dart';

import 'isolate_source.dart';

class TailCliInIsolate {
  // final _controller = StreamController<String>();

  Completer<Process> startupCompleted = Completer<Process>();

  /// Call this method to stop the tail.
  /// It kills the underlying 'tail' process.
  Future<void> stop() async {
    final process = await startupCompleted.future;
    print('stop ${Isolate.current.debugName}');

    // await _controller.close();

    process.kill();
  }

  /// Returns the last lines of [command] and then
  /// follows the file.
  Stream<String> _cliStream(String command) {
    verbose(() => 'tail cli:  $command  ${Isolate.current.debugName}');

    return command.stream();
  }
}

class TailCli {
  TailCli(this.cli);
  IsolateSource<String, String, int, bool> isoStream =
      IsolateSource<String, String, int, bool>();
  String cli;

  Stream<String?> start() {
    isoStream
      ..onStart = _dockerLog
      ..onStop = _dockerLogsStop
      ..start(cli, 0, false);

    return isoStream.stream;
  }

  void stop() {
    isoStream.stop();
  }
}

var _dockerLogsIsolate = TailCliInIsolate();

/////////////////////////////////////////////////
///
/// top level functions required for isolate entry points.
///
/// The following methods are always called in the spawned
/// Isolate.

/// Called when the tail command is to be stopped.
void _dockerLogsStop() {
  _dockerLogsIsolate.stop();
}

/// Called when the tail command is to be started
Stream<String> _dockerLog(String cli, int _, bool __) =>
    _dockerLogsIsolate._cliStream(cli);

class TailCliException implements Exception {
  TailCliException(this.message);
  String message;
}
