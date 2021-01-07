#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

/// Changed the shared dependency to be published

void main(List<String> args) {
  var exe = join(
      Script.current.pathToProjectRoot, 'tool', 'toggle_shared_location.dart');

  '$exe published'.run;
}
