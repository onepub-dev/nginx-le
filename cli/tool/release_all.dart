#! /bin/env dcli

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

void main() {
  var project = DartProject.fromPath('.', search: true);

  var projectRootPath = project.pathToProjectRoot;
  var pubspec = project.pubSpec;
  var currentVersion = pubspec.version;

  /// release shared
  print('Releasing code to pub.dev.');

  './toggle_shared_location.dart published'
      .start(workingDirectory: join(projectRootPath, 'tool'));

  print(orange('Current version is: $currentVersion'));
  var newVersion = askForVersion(currentVersion);

  /// release shared
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../shared'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../shared'));

  /// release container
  'pub upgrade'.start(workingDirectory: join(projectRootPath, '../container'));
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../container'));

  /// release cli
  'pub upgrade'.start(workingDirectory: projectRootPath);
  'pub_release --setVersion=${newVersion.toString()}'
      .start(workingDirectory: projectRootPath);

  print('Activate the just published version');
  'pub global activate nginx_le'.run;
  var name = 'noojee/nginx-le';
  var imageTag = '$name:${newVersion.toString()}';
  'nginx-le build --image=$imageTag'
      .start(workingDirectory: findDockerFilePath());
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
