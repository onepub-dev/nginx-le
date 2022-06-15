#! /bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


// ignore_for_file: file_names

import 'package:dcli/dcli.dart';

void main(List<String> args) {
  final version = args[0];

  final project = DartProject.fromPath('.');

  final projectRootPath = project.pathToProjectRoot;
  print('projectRoot $projectRootPath');

  print('Activate the just published version');
  'pub global activate nginx_le'.run;

  print('Pushing Docker image.');
  const name = 'onepub/nginx-le';
  final imageTag = '$name:$version';

  print('docker path: ${findDockerFilePath()}');
  print(green('Building nginx-le docker image'));
  'nginx-le build -d --image=$imageTag'
      .start(workingDirectory: findDockerFilePath());

  print(green('Pushing docker image: $imageTag and latest'));
  const latestTag = '$name:latest';
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
