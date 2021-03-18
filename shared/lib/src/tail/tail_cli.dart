import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dcli/dcli.dart';

import 'isolate_source.dart';

class TailCliInIsolate {
  // final _controller = StreamController<String>();

  var startupCompleted = Completer<Process>();

  /// Call this method to stop the tail.
  /// It kills the underlying 'tail' process.
  Future<void> stop() async {
    var process = await startupCompleted.future;
    print('stop ${Isolate.current.debugName}');

    // await _controller.close();

      process.kill();
  }

  /// Returns the last [lines] of [containerid]  and then
  /// follows the file.
  Stream<String> _cliStream(String cli) {
    Settings().verbose('tail cli:  $cli  ${Isolate.current.debugName}');

    return cli.stream();
  }
}

class TailCli {
  var isoStream = IsolateSource<String, String, int, bool>();
  String cli;

  TailCli(this.cli);

  Stream<String?> start() {
    isoStream.onStart = _dockerLog;
    isoStream.onStop = _dockerLogsStop;

    isoStream.start(cli, 0, false);

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
Stream<String> _dockerLog(String cli, int _, bool __) {
  return _dockerLogsIsolate._cliStream(cli);
}

class TailCliException implements Exception {
  String message;
  TailCliException(this.message);
}
