#! /bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

void main() {
  /// We take the version from nginx-le shared as all packages must
  /// take their version no. from shared as it is the root dependency
  /// and the first to get published, so if later actions fail
  /// will can only move forward with version no. if shared got published.
  var project = DartProject.fromPath('../../shared', search: true);

  var projectRootPath = project.pathToProjectRoot;
  var pubspec = project.pubSpec;
  var currentVersion = pubspec.version;

  print('projectRoot $projectRootPath');

  /// release shared
  print('Releasing code to pub.dev.');

  // build(currentVersion);
  // exit(1);
  print(orange('Current version is: $currentVersion'));
  var newVersion = askForVersion(currentVersion);

  print(green('Publishing nginx-le-shared'));
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../shared'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../shared'));

  './toggle_shared_location.dart published'
      .start(workingDirectory: join(projectRootPath, 'tool'));

  print(green('Publishing nginx-le-container'));
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../container'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../container'));

  print(green('Publishing nginx-le-cli'));
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../cli'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: projectRootPath);

  build(newVersion);
}

void build(Version newVersion) {
  print('Activate the just published version');
  'pub global activate nginx_le'.run;
  var name = 'noojee/nginx-le';
  var imageTag = '$name:${newVersion.toString()}';

  print('docker path: ${findDockerFilePath()}');
  print(green('Building nginx-le docker image'));
  'nginx-le build -d --image=$imageTag'
      .start(workingDirectory: findDockerFilePath());

  print(green('Pushing docker image: $imageTag and latest'));
  var latestTag = '$name:latest';
  'docker image tag $imageTag $latestTag'.run;

  'docker push $imageTag'.run;
  'docker push $latestTag'.run;
}

String findDockerFilePath() {
  var current = pwd;

  while (current != rootPath) {
    if (exists(join(current, 'Dockerfile'))) {
      return current;
    }

    current = dirname(current);
  }
  return '.';
}
