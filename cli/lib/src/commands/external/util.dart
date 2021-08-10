import 'dart:io';

import 'package:args/args.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';

/// checks the container 'name' and 'containerid' args to see which
/// one was passed.
/// If neither were passed it displays a menu of container ids.
///
/// Returns the selected container by name or containerid.
String containerOrName(ArgParser argParser, ArgResults argResults) {
  var containerid = argResults['containerid'] as String?;
  var name = argResults['name'] as String?;

  if (name != null && containerid != null) {
    printerr('You may only pass one of "name" and "containerid');
    showUsage(argParser);
  }

  if (containerid != null) {
    if (!Containers().existsByContainerId(containerid, excludeStopped: true)) {
      printerr('The passed container id is not running');
      printerr('');
      containerid = null;
    }
  }

  if (containerid == null && name == null) {
    var containers = Containers().containers();

    if (containers.isEmpty) {
      printerr(orange('No docker containers are running.'));
      exit(1);
    }
    var container = menu<Container>(
        options: containers,
        prompt: 'Please select a container to run:',
        format: (item) => '${item.imageid} ${item.name}');
    containerid = container.containerid;
  }

  var target = name;
  target ??= containerid;

  return target!;
}

void showUsage(ArgParser argParser) {
  print(argParser.usage);
  exit(1);
}
