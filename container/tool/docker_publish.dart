#! /bin/env dshell
import 'dart:io';

import 'package:dshell/dshell.dart';

void main(List<String> args) {
  var script = Script.fromFile(Platform.script.toFilePath());

  var root = script.projectRoot;

  var pubspec = PubSpecFile.fromFile(join(root, 'pubspec.yaml'));

  var version = pubspec.version;

  print('Version: $version');

  if (confirm( 'Proceed to publish with this version?')) {
    'nginx-le build -u --image=bsuttonnoojee/nginx-le:$version'
        .start(workingDirectory: '../..');
    // 'docker build -f ../../Dockerfile -t bsuttonnoojee/nginx-le:$version .'.run;
    'docker push bsuttonnoojee/nginx-le:$version'.run;
  } else {
    printerr('publish canceled.');
  }
}
