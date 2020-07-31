#! /bin/env dshell
import 'dart:io';

import 'package:dshell/dshell.dart';

import 'version.dart';

void main() {
  // climb the path searching for the pubspec
  var pubspecPath = findPubSpec();
  var projectRootPath = dirname(pubspecPath);
  var pubspec = getPubSpec(pubspecPath);
  var currentVersion = pubspec.version;

  /// release shared
  print('Releasing code to pub.dev.');

  var newVersion = askForVersion(currentVersion);

  /// release shared
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../shared'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../shared'));

  /// release cli
  'pub upgrade'.start(workingDirectory: projectRootPath);
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: projectRootPath);

  var name = 'noojee/nginx-le';
  var imageTag = '$name:${newVersion.toString()}';
  'nginx-le build --image=$imageTag'
      .start(workingDirectory: join(projectRootPath, '..'));
  var latestTag = '$name:latest';
  'docker image tag $imageTag $latestTag'.run;

  'docker push $imageTag'.run;
  'docker push $latestTag'.run;
}

/// Returns the path to the pubspec.yaml.
String findPubSpec() {
  var pubspecName = 'pubspec.yaml';
  var cwd = pwd;
  var found = true;

  var pubspecPath = join(cwd, pubspecName);
  // climb the path searching for the pubspec
  while (!exists(pubspecPath)) {
    cwd = dirname(cwd);
    // Have we found the root?
    if (cwd == rootPath) {
      found = false;
      break;
    }
    pubspecPath = join(cwd, pubspecName);
  }

  if (!found) {
    print('Unable to find pubspec.yaml, run release from the '
        "package's root directory.");
    exit(-1);
  }
  return truepath(pubspecPath);
}

/// Read the pubspec.yaml file.
PubSpecFile getPubSpec(String pubspecPath) {
  var pubspec = PubSpecFile.fromFile(pubspecPath);
  return pubspec;
}
