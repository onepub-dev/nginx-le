#! /bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */




import 'dart:io';

import 'package:dcli/dcli.dart';

void main(List<String> args) {
  final script = DartScript.fromFile(Platform.script.toFilePath());

  final root = script.pathToProjectRoot;

  final pubspec = PubSpec.fromFile(join(root, 'pubspec.yaml'));

  final version = pubspec.version;

  print('Version: $version');

  if (confirm('Proceed to publish with this version?')) {
    'nginx-le build -u --image=bsuttonnoojee/nginx-le:$version'
        .start(workingDirectory: '../..');
    // 'docker build -f ../../Dockerfile -t bsuttonnoojee/nginx-le:$version .'.run;
    'docker push bsuttonnoojee/nginx-le:$version'.run;
  } else {
    printerr('publish canceled.');
  }
}
