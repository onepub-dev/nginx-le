import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';

import 'isolate_source.dart';

class DockerLogsInIsolate {
  // final _controller = StreamController<String>();

  var startupCompleted = Completer<Process>();

  /// Call this method to stop the tail.
  /// It kills the underlying 'tail' process.
  Future<void> stop() async {
    var process = await startupCompleted.future;
    print('stop ${Isolate.current.debugName}');

    // await _controller.close();

    if (process != null) {
      (await process).kill();
    }
  }

  /// Returns the last [lines] of [containerid]  and then
  /// follows the file.
  @visibleForTesting
  Stream<String> dockerLog(String containerid, {int lines = 100, bool follow = false}) {
    Settings().verbose('docker logs:  $lines  ${Isolate.current.debugName}');

    var cmd = 'docker logs --tail $lines $containerid';

    if (follow) cmd += ' -f';

    return cmd.stream();
  }
}

class DockerLogs {
  var isoSource = IsolateSource<String, String, int, bool>();
  String containerid;
  int lines;
  bool follow;

  DockerLogs(this.containerid, this.lines, {this.follow = false});

  Stream<String> start() {
    isoSource.onStart = _dockerLog;
    isoSource.onStop = _dockerLogsStop;

    isoSource.start(containerid, lines, follow);

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
Stream<String> _dockerLog(String containerid, int lines, bool follow) {
  return _dockerLogsIsolate.dockerLog(containerid, lines: lines, follow: follow);
}

class DockerLogsException implements Exception {
  String message;
  DockerLogsException(this.message);
}
