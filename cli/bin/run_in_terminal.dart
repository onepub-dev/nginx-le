#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

/// Runs a command with tty access.

void main(List<String> args) {
  Settings().setVerbose(enabled: true);
  startFromArgs(args[0], args.sublist(1), terminal: true, progress: Progress.print());
}
