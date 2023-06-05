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

class TailInIsolate {
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

  /// Returns the last [lines] of [filename]  and then
  /// follows the file.
  Stream<String> tail(String filename, {int lines = 100, bool follow = false}) {
    verbose(() => 'tail: $filename $lines  ${Isolate.current.debugName}');

    var cmd = 'tail -n $lines';

    /// We use -F as certbot log rotates the files and -F is specifically used
    /// in this situation.
    if (follow) {
      cmd += ' -F';
    }

    cmd += ' $filename';

    return cmd.stream();
  }
}

class Tail {
  Tail(this.filename, this.lines, {this.follow = false}) {
    if (!exists(filename)) {
      throw TailException('The file $filename does not exist');
    }
  }
  IsolateSource<String, String, int, bool> isoStream =
      IsolateSource<String, String, int, bool>();
  String filename;
  int lines;
  bool follow;

  Future<Stream<String?>> start() async {
    isoStream
      ..onStart = tail
      ..onStop = tailStop;
    // ignore: discarded_futures
    await isoStream.start(filename, lines, follow);

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

TailInIsolate tallTail = TailInIsolate();
Stream<String>? tailStream;

/////////////////////////////////////////////////
///
/// top level functions required for isolate entry points.
///
/// The following methods are always called in the spawned
/// Isolate.

/// Called when the tail command is to be stopped.
void tailStop() {
  unawaited(tallTail.stop());
}

/// Called when the tail command is to be started
// ignore: avoid_positional_boolean_parameters
Stream<String> tail(String filename, int lines, bool follow) =>
    tallTail.tail(filename, lines: lines, follow: follow);

class TailException implements Exception {
  TailException(this.message);
  String message;
}
