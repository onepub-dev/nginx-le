import 'dart:async';

class StartMessage<R, ARG1, ARG2, ARG3> {
  final Stream<R> Function(ARG1, ARG2, ARG3) startFunction;
  final ARG1 argument1;
  final ARG2 argument2;
  final ARG3 argument3;

  StartMessage(this.startFunction, this.argument1, this.argument2, this.argument3);

  FutureOr<Stream<R>> call() async => await startFunction(argument1, argument2, argument3);
}

class StopMessage {
  final void Function() stopFunction;

  StopMessage(this.stopFunction);

  void call() async => await stopFunction();
}

/// Sent by the isolate to indicated that it has shutdown cleanly and can now be terminated.
class StoppedMessage {}
