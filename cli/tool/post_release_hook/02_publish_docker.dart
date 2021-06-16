#! /bin/env dcli

import 'package:dcli/dcli.dart';

void main(List<String> args) {
  final version = args[0];

  var project = DartProject.fromPath('.', search: true);

  var projectRootPath = project.pathToProjectRoot;
  print('projectRoot $projectRootPath');

  print('Activate the just published version');
  'pub global activate nginx_le'.run;

  print('Pushing Docker image.');
  var name = 'noojee/nginx-le';
  var imageTag = '$name:$version';

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
