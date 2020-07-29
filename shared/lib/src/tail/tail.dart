import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dshell/dshell.dart';

import 'isolate_source.dart';

class TailInIsolate {
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

  /// Returns the last [lines] of [filename]  and then
  /// follows the file.
  Stream<String> tail(String filename, {int lines = 100, bool follow = false}) {
    Settings().verbose('tail: $filename $lines  ${Isolate.current.debugName}');

    var cmd = 'tail -n $lines';

    /// We use -F as certbot log rotates the files and -F is specifically used
    /// in this situation.
    if (follow) cmd += ' -F';

    cmd += ' $filename';

    return cmd.stream();
  }
}

class Tail {
  var isoStream = IsolateSource<String, String, int, bool>();
  String filename;
  int lines;
  bool follow;

  Tail(this.filename, this.lines, {this.follow = false}) {
    if (!exists(filename)) {
      throw TailException('The file $filename does not exist');
    }
  }

  Stream<String> start() {
    isoStream.onStart = tail;
    isoStream.onStop = tailStop;

    isoStream.start(filename, lines, follow);

    // set up the handler to recieve the stream data
    // process it and return.
    // isoStream.stream.listen((data) {
    //   print('main: $data');
    // });

    return isoStream.stream;
  }

  void stop() {
    isoStream.stop();
  }
}

var tallTail = TailInIsolate();
Stream<String> tailStream;

/////////////////////////////////////////////////
///
/// top level functions required for isolate entry points.
///
/// The following methods are always called in the spawned
/// Isolate.

/// Called when the tail command is to be stopped.
void tailStop() {
  tallTail.stop();
}

/// Called when the tail command is to be started
Stream<String> tail(String filename, int lines, bool follow) {
  return tallTail.tail(filename, lines: lines, follow: follow);
}

class TailException implements Exception {
  String message;
  TailException(this.message);
}
