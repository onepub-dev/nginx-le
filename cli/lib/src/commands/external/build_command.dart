import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:uuid/uuid.dart';

class BuildCommand extends Command<void> {
  BuildCommand() {
    argParser
      ..addOption('image',
          abbr: 'i',
          help:
              'The docker image name in the form --image="repo/image:version"')
      ..addFlag('update-dcli',
          abbr: 'u',
          help:
              'Pass this flag to force the build to pull the latest version of dart/dcli',
          negatable: false)
      ..addFlag('overwrite',
          abbr: 'o',
          help: 'If an image with the same name exists then replace it.',
          negatable: false)
      ..addFlag('debug',
          abbr: 'd',
          negatable: false,
          help: 'Outputs additional build information');
  }
  @override
  String get description => 'Builds your nginx container';

  @override
  String get name => 'build';
  @override
  void run() {
    final results = argResults!;

    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    final overwrite = results['overwrite'] as bool?;

    final dockerPath = findDockerfile();

    var imageName = argResults!['image'] as String?;

    if (imageName == null) {
      final repo = ask('ImageName:', defaultValue: 'noojee/nginx-le');
      final currentVersion = DartProject.self.pubSpec.version!.toString();
      print('Current version: $currentVersion');
      final version = ask('Version:',
          defaultValue: currentVersion, validator: Ask.required);
      imageName = '$repo:$version';
    }

    final latest = genLatestTag(imageName);

    // check for an existing image.
    var image = Images().findByName(imageName);
    if (image != null) {
      if (!overwrite!) {
        printerr(
            'The image $imageName already exists. Choose a different name or '
            'use --overwrite to replace it.');
        showUsage(argParser);
      } else {
        /// delete the image an all its associated containers.
        deleteImage(image);
      }
    }
    final pulldcli = results['update-dcli'] as bool;

    /// force dcli to pull the latest version.
    if (pulldcli) {
      replace(join(dockerPath, 'Dockerfile'), RegExp('# flush-cache:.*'),
          '# flush-cache: ${const Uuid().v4()}');
      'update-dcli.txt'.write(const Uuid().v4());
    }

    // make certain we always have the latest source
    replace(join(dockerPath, 'Dockerfile'), RegExp('# update-source:.*'),
        '# update-source: ${const Uuid().v4()}');
    'update-source.txt'.write(const Uuid().v4());

    print(green('Building nginx-le docker image $imageName '));

    // get the latest ubuntu image before we build.
    Images().pull(fullname: 'ubuntu:20.04');

    /// required to give docker access to our ssh keys.
    'docker build -t $imageName -t $latest .'
        .start(workingDirectory: dockerPath);

    'docker push $imageName'.run;
    'docker push $latest'.run;

    /// get the new image.
    image = Images().findByName(imageName);
    ConfigYaml()
      ..image = image
      ..save();

    print('');
    print(green(
        "Build Complete. You should now run 'nginx-le config' to reconfigure "
        'your system to use the new image'));
  }

  // ignore: missing_return
  String findDockerfile() {
    var projectPath = DartProject.self.pathToProjectRoot;
    if (DartScript.self.isPubGlobalActivated || DartScript.self.isCompiled) {
      projectPath = pwd;
    }
    if (exists(join(projectPath, 'Dockerfile'))) {
      return projectPath;
    }

    if (exists(join(projectPath, '..', 'Dockerfile'))) {
      return join(projectPath, '..');
    } else {
      printerr('The Dockerfile must be present in the project root at '
          '${truepath(projectPath)}.');
      showUsage(argParser);
      exit(1);
    }
  }

  /// delete an [image] and all its associated containers.
  void deleteImage(Image image) {
    final containers = Containers().findByImage(image);
    for (final container in containers) {
      /// if the container is running ask to stop it.
      if (container.isRunning) {
        print(orange(
            'The container ${container.containerid} ${container.name} is '
            'running. To delete the container it must be stopped.'));
        if (confirm('Stop ${container.containerid} ${container.name}')) {
          container.stop();
        } else {
          printerr(
              red("Can't proceed when an dependant container is running."));
          exit(1);
        }
      }
      container.delete();
    }
    image.delete(force: true);
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}

String genLatestTag(String imageName) {
  if (imageName.contains(':')) {
    final parts = imageName.split(':');
    return '${parts[0]}:latest';
  } else {
    return '$imageName:latest';
  }
}
