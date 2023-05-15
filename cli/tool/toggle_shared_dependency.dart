#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */



import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

/// Changed the shared dependency to be published

void main(List<String> args) {
  final exe = join(
      DartScript.self.pathToProjectRoot, 'tool', 'toggle_shared_location.dart');

  '$exe local'.run;
}
