#! /usr/bin/env dshell
import 'package:dshell/dshell.dart';

/// Runs a command with tty access.

void main(List<String> args) {
  Settings().setVerbose(enabled: true);
  startFromArgs(args[0], args.sublist(1),
      terminal: true, progress: Progress.print());
}
