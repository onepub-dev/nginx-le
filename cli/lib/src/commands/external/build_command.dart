import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:uuid/uuid.dart';

class BuildCommand extends Command<void> {
  @override
  String get description => 'Builds your nginx container';

  @override
  String get name => 'build';

  BuildCommand() {
    argParser.addOption('image',
        abbr: 'i',
        help: 'The docker image name in the form --image="repo/image:version"');

    argParser.addFlag('update-dcli',
        abbr: 'u',
        help:
            'Pass this flag to force the build to pull the latest version of dart/dcli',
        negatable: false,
        defaultsTo: false);

    argParser.addFlag('overwrite',
        abbr: 'o',
        help: 'If an image with the same name exists then replace it.',
        negatable: false,
        defaultsTo: false);

    argParser.addFlag('debug',
        abbr: 'd',
        negatable: false,
        help: 'Outputs additional build information');
  }
  @override
  void run() {
    var results = argResults!;

    var debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    var overwrite = results['overwrite'] as bool?;

    var dockerPath = findDockerfile();

    var imageName = argResults!['image'] as String?;

    if (imageName == null) {
      var repo = ask('ImageName:', defaultValue: 'noojee/nginx-le');
      print('Current version: $packageVersion');
      var version = ask('Version:',
          defaultValue: packageVersion, validator: Ask.required);
      imageName = '$repo:$version';
    }

    // check for an existing image.
    var image = Images().findByFullname(imageName);
    if (image != null) {
      if (!overwrite!) {
        printerr(
            'The image $imageName already exists. Choose a different name or use --overwrite to replace it.');
        showUsage(argParser);
      } else {
        /// delete the image an all its associated containers.
        deleteImage(image);
      }
    }
    var pulldcli = results['update-dcli'] as bool;

    /// force dcli to pull the latest version.
    if (pulldcli) {
      replace(join(dockerPath, 'Dockerfile'), RegExp('# flush-cache:.*'),
          '# flush-cache: ${Uuid().v4()}');
      'update-dcli.txt'.write(Uuid().v4());
    }

    print(green('Building nginx-le docker image $imageName '));

    // get the latest ubuntu image before we build.
    Images().pull(fullname: 'ubuntu:20.04');

    /// required to give docker access to our ssh keys.
    'docker build -t $imageName .'.start(workingDirectory: dockerPath);

    /// get the new image.
    Images().flushCache();
    image = Images().findByFullname(imageName);
    var config = ConfigYaml();
    config.image = image;
    config.save();

    print(green(
        "Build Complete. You should now run 'nginx-le config' to reconfigure your system to use the new image"));
  }

  // ignore: missing_return
  String findDockerfile() {
    var projectPath = DartProject.current.pathToProjectRoot;
    if (Script.current.isPubGlobalActivated || Script.current.isCompiled) {
      projectPath = pwd;
    }
    if (exists(join(projectPath, 'Dockerfile'))) return projectPath;

    if (exists(join(projectPath, '..', 'Dockerfile'))) {
      return join(projectPath, '..');
    } else {
      printerr(
          'The Dockerfile must be present in the project root at ${truepath(projectPath)}.');
      showUsage(argParser);
      exit(1);
    }
  }

  /// delete an [image] and all its associated containers.
  void deleteImage(Image image) {
    var containers = Containers().findByImage(image);
    for (var container in containers) {
      /// if the container is running ask to stop it.
      if (container.isRunning) {
        print(orange(
            'The container ${container.containerid} ${container.names} is running. To delete the container it must be stopped.'));
        if (confirm('Stop ${container.containerid} ${container.names}')) {
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
