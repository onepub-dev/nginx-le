#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';
import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:path/path.dart';

/// Run this script to toggle how nginx_le_shared is imported as a
/// dependency in the cli and container pubspec.yaml files.
///
/// In 'local' mode the shared package is added as a dependency override.
/// In 'published' mode the shared package is referenced via pub.dev.
///
/// You want to run nginx_le_shared in local mode when doing development
/// but you MUST toggle it to 'published' mode to do a release to pub.dev.

void main(List<String> args) {
  final parser = ArgParser()
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Logs additional details to the cli',
    );

  final parsed = parser.parse(args);

  Settings().setVerbose(enabled: parsed.wasParsed('verbose'));

  if (parsed.rest.length != 1) {
    printerr(red('You must passed a command: local | published'));
    showUsage(parser);
  }

  final command = parsed.rest[0];

  final cliPubspec = DartScript.self.pathToPubSpec;
  final containerPubspec = join(
      DartScript.self.pathToProjectRoot, '..', 'container', 'pubspec.yaml');

  if (command == 'local') {
    makeLocal(cliPubspec, containerPubspec);
  } else if (command == 'published') {
    makePublished(cliPubspec, containerPubspec);
  } else {
    printerr(red(
        'Invalid command passed. Expected local | published. Found $command'));
    showUsage(parser);
  }

  // print('running pub upgrades');
  // 'pub upgrade'.start(workingDirectory: Script.current.pathToProjectRoot);
  // 'pub upgrade'.start(workingDirectory: dirname(containerPubspec));
}

void makePublished(String cliPubspec, String containerPubspec) {
  print(red('Processing cli'));
  makePubDev(cliPubspec);

  print('');
  print(red('Processing container'));

  makePubDev(containerPubspec);
}

void makeLocal(String cliPubspec, String containerPubspec) {
  print(red('Processing cli'));
  makeRelative(cliPubspec);

  print('');
  print(red('Processing container'));

  makeRelative(containerPubspec);
}

void makeRelative(String pathToPubSpec) {
  final pubspec = PubSpec.fromFile(pathToPubSpec);

  var found = false;
  for (final dep in pubspec.dependencyOverrides.values) {
    if (dep.name == 'nginx_le_shared') {
      found = true;
      break;
    }
  }

  if (found) {
    print(orange('nginx_le_shared is already a relative dependency'));
  } else {
    pathToPubSpec
      ..append('')
      ..append('dependency_overrides:')
      ..append('  nginx_le_shared:')
      ..append('    path:')
      ..append('      ../shared');

    'dart pub get'.start(workingDirectory: dirname(pathToPubSpec));
    print(green('nginx_le_shared is now a relative dependency'));
  }
}

void makePubDev(String pathToPubSpec) {
  final pubspec = PubSpec.fromFile(pathToPubSpec);

  var found = false;
  for (final dep in pubspec.dependencyOverrides.values) {
    if (dep.name == 'nginx_le_shared') {
      found = true;
      break;
    }
  }

  if (!found) {
    print(orange('nginx_le_shared is already a pub.dev dependency'));
  } else {
    final backup = '$pathToPubSpec.bak';
    if (exists(backup)) {
      delete(backup);
    }
    move(pathToPubSpec, backup);

    pathToPubSpec.truncate();

    var inOverride = false;
    read(backup).forEach((line) {
      if (line.startsWith('dependency_overrides')) {
        inOverride = true;
      } else {
        if (inOverride) {
          if (!line.startsWith(' ')) {
            inOverride = false;
          }
        }
      }

      if (!inOverride) {
        pathToPubSpec.append(line);
      }
    });

    delete(backup);

    'dart pub get'.start(workingDirectory: dirname(pathToPubSpec));
    print(green('nginx_le_shared is now a pub.dev dependency'));
  }
}

void showUsage(ArgParser parser) {
  print('Toggles how cli and container depend on the shared library.');
  print('Usage: toggle_shared_location.dart -v local | published');
  print('local - addes a dependency override so the local '
      'copy of shared is used');
  print('publish - removes any dependency override so the pub.dev version of '
      'shared is used');
  print(parser.usage);
  exit(1);
}
