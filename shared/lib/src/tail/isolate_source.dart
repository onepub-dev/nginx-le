/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


// for exit();
import 'dart:async';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:dcli/dcli.dart';

import 'messages.dart';

/// Provides a library to stream data to and from an isolate.
///
/// [IsolateSource] lets you setup a processing pipe line using an
/// [Isolate] without having to deal with the low level details of
/// setting up an [Isolate].
///
/// The three main methods are:
///
/// [IsolateSteam.send()] - sends a data packet to the isolate
/// [IsolateSource.process()] - process data in the isolate
/// [IsolateSource.receive()] - recieves processed data back from the isolate.
///
/// You will normally set the above methods up in you code in reverse order
/// [IsolateSteam.recieve()]
/// [IsolateSteam.process()]
/// [IsolateSteam.send()]
///
/// This is because you need to have you processing pipeline setup before you
/// start sending data into it.
///
/// Calling [IsolateSteam.send()] before configuring [IsolateSteam.recieve()]
/// and [IsolateSteam.process()] may cause
/// [IsolateSteam.send()] to hang.
///
/// When stoppig a stream you will often want to ensure that you have recieved
/// all of the data back from the isolate. To do this call
/// [IsolateSource.stop()]
/// and then use [IsolateSource.onStopped()] to be notified when
/// the Isolate has processed the last packet.
///
/// [IsolateSource] guaentees that you will [IsolateSteam.recieve()] the last
///  data packet.
/// before [IsolateSource.onStopped()] is called.
///
///
/// ```dart
///
/// void convert(Track from, Track to)
/// {
///   var isoStream = IsolateSource();
///
///  var toPath = to.path;
///   var toFile = File(toPath);
///
///   /// Handle the converted data coming back.
///   isoStream.recieve((converted) {
///     toFile.append(converted);
///   });
///
///
///   // set up the handler to recieve the stream data
///   // process it and return.
///   isoStream.process((data, responseStream) {
///     // this code is called in the isolate.
///     var converted = convert(data, to);
///     /// send the data back using the response stream.
///     responseStream.add(converted);
///
///   });
///
///
///
///   var pathFrom = from.path;
///   var file = File(pathFrom);
///   for (var data : file.readNextBlock())
///   {
///     isoStream.send(data);
///   }
/// }
/// ```

typedef Processor<R, ARG1, ARG2, ARG3> = Stream<R> Function(
    ARG1 arg1, ARG2 arg2, ARG3 arg3);
typedef ResultStream<R> = void Function(R data);

// Example of bi-directional communication between a main thread and isolate.

/// [ARG1] etc is the type of data we send to the isolate.
/// Standard [Stream] rules apply for the type of objects we can send to
/// an isolate. If you want to send a complex object then you need
/// to do something like jsonise the data.
/// [R] is the type of data we recieve back from the isolate.
/// Standard [Stream] rules apply to to the type of objects the
/// isolate can return.
class IsolateSource<R, ARG1, ARG2, ARG3> {
  ///
  IsolateSource();

  final StreamController<R?> _controller = StreamController<R>();

  Stream<R?> get stream => _controller.stream;

  /// Set the method to be called in the isolate which
  /// performs the necessary processes and returns
  /// the resulting stream of data.
  Processor<R, ARG1, ARG2, ARG3>? onStart;

  void Function()? onStop;

  //  set processor(Processor processor) =>
  //      processorMap[receiveFromIsolatePort.sendPort] = processor;

  // /// The isolate we spawn.
  Isolate? _isolate;

  late SendPort sendToIsolatePort;

  ReceivePort? receiveFromIsolatePort;

  /// Completes once the isolate is set up
  /// and we have its sendPort.
  final initialised = Completer<bool>();

  void stop() {
    verbose(() => 'Sending StopMessage');
    sendToIsolatePort.send(StopMessage(onStop));
    if (_isolate != null) {
      _isolate!.kill();
    }
    if (receiveFromIsolatePort != null) {
      receiveFromIsolatePort!.close();
    }
    _controller.close();
  }

  Future<void> start(ARG1 arg1, ARG2 arg2, ARG3 arg3) async {
    verbose(() => 'start for $arg1, $arg2, $arg3');
    await initIsolate();
    await initialised.future;

    final message =
        StartMessage<R, ARG1, ARG2, ARG3>(onStart, arg1, arg2, arg3);

    verbose(() => 'sending start message for $arg1, $arg2, $arg3');
    sendToIsolatePort.send(message);
  }

  ///
  Future<void> initIsolate() async {
    receiveFromIsolatePort = ReceivePort();

    var forwardCount = 0;

    ///
    /// Create the listner to recieve data from the isolate
    /// listen to data coming back from the isolate.
    ///
    receiveFromIsolatePort!.listen((dynamic data) {
      if (data is SendPort) {
        /// We have recieved the isolates sendport so we can communicate with
        /// it now.
        sendToIsolatePort = data;
        initialised.complete(true);
        return;
      }

      if (data is StoppedMessage) {
        verbose(() => 'Received StoppedMessage killing isolate');
        receiveFromIsolatePort!.close();
        _isolate!.kill();
        _controller.close();
        return;
      } else if (data is ErrorResult) {
        _controller
          ..addError(data)
          ..close();
      } else if (data is List<dynamic>) {
        /// this is normally a stack trace. need a better way of dealing
        /// with these.
        printerr('Unexpected response from isolate:');
        data.forEach(print);
      } else {
        /// We recieve the stream of data from the isolate here.
        /// So now send it up to our master.
        verbose(() => 'forwarding: ${++forwardCount} $data');
        _controller.sink.add(data as R?);
      }
    }, onDone: () => verbose(() => 'IsolatePort done'));

    _isolate = await Isolate.spawn<SendPort>(
        // ignore: inference_failure_on_function_invocation
        spawnEntryPoint,
        receiveFromIsolatePort!.sendPort,
        debugName: 'tail',
        onExit: receiveFromIsolatePort!.sendPort,
        onError: receiveFromIsolatePort!.sendPort);
  }

  /// Isolates entry point used by the above call to [initIsolate].
  ///
  /// Isolate entry points must be global functions or
  /// static methods.
  static void spawnEntryPoint<R, ARG1, ARG2>(SendPort sendToMainPort) {
    /// we are in a different isolate so the settings don't transfer across.
    Settings().setVerbose(enabled: true);
    final recieveFromMainPort = ReceivePort();

    /// Immediately Send our send port to the main thread so
    /// it can send us data.
    sendToMainPort.send(recieveFromMainPort.sendPort);

    /// Process messages from the main isolate.
    recieveFromMainPort.listen((dynamic message) async {
      if (message is StopMessage) {
        if (message.stopFunction != null) {
          message.stopFunction!();
        }
        verbose(() => 'sending StoppedMessage');
        sendToMainPort.send(StoppedMessage());
        return;
      }

      /// Run the passed function processing its output.
      var sentCount = 0;
      try {
        final currentMessage =
            message as StartMessage<String, String, int, bool>;

        final startFunction = currentMessage.startFunction!;
        final argument1 = currentMessage.argument1;
        final argument2 = currentMessage.argument2;
        final argument3 = currentMessage.argument3;
        verbose(() =>
            'Isolate recieved Start Message $argument1 $argument2 $argument3');
        startFunction(argument1, argument2, argument3).listen((dynamic event) {
          verbose(() => 'Sending ${++sentCount} $event');
          sendToMainPort.send(event);
        }).onDone(() {
          verbose(() => 'onDone returned by controller');

          /// notify upstream that we are done.
          sendToMainPort.send(StoppedMessage());
        });
      }
      // ignore: avoid_catches_without_on_clauses
      catch (error) {
        try {
          sendToMainPort.send(Result<R>.error(error));
        }
        // ignore: avoid_catches_without_on_clauses
        catch (error) {
          sendToMainPort.send(Result<R>.error(
              "can't send error with big stackTrace, error is : "
              '${error.toString()}'));
        }
      }
    });
  }
}
