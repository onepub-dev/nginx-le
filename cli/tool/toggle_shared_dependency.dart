#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

/// Changed the shared dependency to be published

void main(List<String> args) {
  final exe = join(
      DartScript.self.pathToProjectRoot, 'tool', 'toggle_shared_location.dart');

  '$exe local'.run;
}
