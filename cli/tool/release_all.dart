#! /bin/env dcli

import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:pub_release/pub_release.dart';

void main(List<String> args) {
  var parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', help: 'Adds additional logging')
    ..addFlag('help', abbr: 'h', help: 'Prints this help message')
    ..addFlag('test',
        abbr: 't',
        defaultsTo: true,
        help: 'Causes unit tests to be run as part of the release.');

  ArgResults parsed;

  try {
    parsed = parser.parse(args);
  } on FormatException catch (e) {
    printerr(red(e.message));
    showUsage(parser);
    exit(1);
  }

  Settings().setVerbose(enabled: parsed['verbose'] as bool);

  if (parsed['help'] as bool) {
    showUsage(parser);
    exit(1);
  }

  var runTests = parsed['test'] as bool ? '--test' : '--no-test';

  var cliProject = DartProject.self;

  /// We take the version from nginx-le shared as all packages must
  /// take their version no. from shared as it is the root dependency
  /// and the first to get published, so if later actions fail
  /// will can only move forward with version no. if shared got published.
  var project = DartProject.fromPath(
      join(cliProject.pathToProjectRoot, '../shared'),
      search: true);

  var projectRootPath = project.pathToProjectRoot;
  var pubspec = project.pubSpec;
  var currentVersion = pubspec.version!;

  print('projectRoot $projectRootPath');

  /// release shared
  print('Releasing code to pub.dev.');

  // build(currentVersion);
  // exit(1);
  print(orange('Current version is: $currentVersion'));
  var newVersion = askForVersion(currentVersion);

  /// shared
  print(green('Publishing nginx-le-shared'));
  'pub upgrade --major-versions'.start(workingDirectory: join(projectRootPath, '../shared'));
  'git add pubspec.lock'
      .start(workingDirectory: join(projectRootPath, '../shared'));
  conditionalCommit(
      message: 'Upgraded packages as part of release process',
      path: '../shared',
      projectRootPath: projectRootPath);
  'pub_release --autoAnswer  $runTests --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../shared'));

  // toggle to the published version of shared.
  './toggle_shared_location.dart published'
      .start(workingDirectory: join(projectRootPath, '..', 'cli', 'tool'));

  // the toggle action updates the yaml.
  'git add ../cli/pubspec.lock'.start(workingDirectory: projectRootPath);
  'git add ../cli/pubspec.yaml'.start(workingDirectory: projectRootPath);
  'git add ../container/pubspec.yaml'.start(workingDirectory: projectRootPath);
  'git add ../container/pubspec.lock'.start(workingDirectory: projectRootPath);

  conditionalCommit(
      message: 'Toggled path to shared package',
      path: '../shared',
      projectRootPath: projectRootPath);

  // container
  print(green('Publishing nginx-le-container'));
  'pub upgrade --major-versions'.start(workingDirectory: join(projectRootPath, '../container'));
  'git add pubspec.lock'
      .start(workingDirectory: join(projectRootPath, '../container'));
  conditionalCommit(
      message: 'Upgraded packages as part of release process',
      path: '../container',
      projectRootPath: projectRootPath);
  'pub_release --autoAnswer  $runTests --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../container'));

  // cli
  print(green('Publishing nginx-le-cli'));
  'pub upgrade --major-versions'.start(workingDirectory: join(projectRootPath, '../cli'));
  'git add pubspec.lock'
      .start(workingDirectory: join(projectRootPath, '../cli'));
  conditionalCommit(
      message: 'Upgraded packages as part of release process',
      path: '../cli',
      projectRootPath: projectRootPath);
  'pub_release --autoAnswer $runTests  --setVersion=${newVersion.toString()}'
      .start(workingDirectory: join(projectRootPath, '../cli'));

  build(newVersion);
}

void showUsage(ArgParser parser) {
  print(
      'Releases all nginx-le packages to pub.dev and pushes the nginx-le docker container');
  print(parser.usage);
}

void conditionalCommit(
    {String? message, String? path, String? projectRootPath}) {
  final outstanding = 'git status --porcelain'.toList();

  if (outstanding.isNotEmpty) {
    'git commit -m "$message"'
        .start(workingDirectory: join(projectRootPath!, path));
  }
}

void build(Version? newVersion) {
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
