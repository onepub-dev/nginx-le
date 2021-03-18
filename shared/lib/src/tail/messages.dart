import 'dart:async';

class StartMessage<R, ARG1, ARG2, ARG3> {
  final Stream<R> Function(ARG1, ARG2, ARG3)? startFunction;
  final ARG1 argument1;
  final ARG2 argument2;
  final ARG3 argument3;

  StartMessage(
      this.startFunction, this.argument1, this.argument2, this.argument3);

  Stream<R> call() => startFunction!(argument1, argument2, argument3);
}

class StopMessage {
  final void Function()? stopFunction;

  StopMessage(this.stopFunction);

  void call() => stopFunction!();
}

/// Sent by the isolate to indicated that it has shutdown cleanly and can now be terminated.
class StoppedMessage {}
