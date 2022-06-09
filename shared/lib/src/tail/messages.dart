/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


import 'dart:async';

class StartMessage<R, ARG1, ARG2, ARG3> {
  StartMessage(
      this.startFunction, this.argument1, this.argument2, this.argument3);

  final Stream<R> Function(ARG1, ARG2, ARG3)? startFunction;
  final ARG1 argument1;
  final ARG2 argument2;
  final ARG3 argument3;

  Stream<R> call() => startFunction!(argument1, argument2, argument3);
}

class StopMessage {
  StopMessage(this.stopFunction);
  final void Function()? stopFunction;

  void call() => stopFunction!();
}

/// Sent by the isolate to indicated that it has shutdown cleanly and
///  can now be terminated.
class StoppedMessage {}
