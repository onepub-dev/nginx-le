/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import 'isolate_source.dart';

class DockerLogsInIsolate {
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

  /// Returns the last [lines] of [containerid]  and then
  /// follows the file.
  @visibleForTesting
  Stream<String> dockerLog(String containerid,
      {int lines = 100, bool follow = false}) {
    verbose(() => 'docker logs:  $lines  ${Isolate.current.debugName}');

    var cmd = 'docker logs --tail $lines $containerid';

    if (follow) {
      cmd += ' -f';
    }

    return cmd.stream();
  }
}

class DockerLogs {
  DockerLogs(this.containerid, this.lines, {this.follow = false});
  IsolateSource<String, String, int, bool> isoSource =
      IsolateSource<String, String, int, bool>();
  String containerid;
  int lines;
  bool follow;

  Stream<String?> start() {
    isoSource
      ..onStart = _dockerLog
      ..onStop = _dockerLogsStop
      ..start(containerid, lines, follow);

    return isoSource.stream;
  }

  void stop() {
    isoSource.stop();
  }
}

var _dockerLogsIsolate = DockerLogsInIsolate();

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
Stream<String> _dockerLog(String containerid, int lines, bool follow) =>
    _dockerLogsIsolate.dockerLog(containerid, lines: lines, follow: follow);

class DockerLogsException implements Exception {
  DockerLogsException(this.message);
  String message;
}
