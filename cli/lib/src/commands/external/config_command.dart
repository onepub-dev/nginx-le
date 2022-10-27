/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../content_providers/content_provider.dart';
import '../../content_providers/content_providers.dart';
import '../../util/ask_fqdn_validator.dart';

/// Starts nginx and the certbot scheduler.
class ConfigCommand extends Command<void> {
  ConfigCommand() {
    /// argParser.addOption('template')
    argParser.addFlag('debug',
        negatable: false,
        abbr: 'd',
        help: 'Outputs additional logging information and puts the container '
            'into debug mode');
  }
  @override
  String get description => 'Allows you to configure your Nginx-LE server';

  @override
  String get name => 'config';

  @override
  void run() {
    print('Nginx-LE config Version:$packageVersion');
    final debug = argResults!['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    final config = ConfigYaml();

    selectFQDN(config);
    selectTLD(config);
    selectMode(config);
    selectCertType(config);
    selectAuthProvider(config);
    selectContentProvider(config);
    selectStartMode(config);

    selectEmail(config);
    selectStartMethod(config);

    const containerName = 'nginx-le';

    final image = selectImage(config);

    config.save();
    print('Configuration saved.');

    ContentProviders().getByName(config.contentProvider)!
      ..createLocationFile()
      ..createUpstreamFile();

    if (config.startMethod != ConfigYaml.startMethodDockerCompose) {
      deleteOldContainers(containerName, image);
      createContainer(image, config, debug: debug);
    } else {
      selectContainer(config);
    }

    /// save the new container id.
    config.save();
  }

  void deleteOldContainers(String containerName, Image image) {
    final existing = Containers().findByName(containerName);

    if (existing != null) {
      print(orange('A container with the name $containerName already exists.'));
      if (!confirm(
          'Do you want to delete the older container and create one with '
          'the new settings?')) {
        print(orange('Container does not reflect your new settings!'));
        exit(-1);
      } else {
        if (existing.isRunning) {
          print('The old container is running. To delete the container it must '
              'be stopped.');
          if (confirm(
              'Do you want the container ${existing.containerid} stopped?')) {
            existing.stop();
          } else {
            printerr(red(
                'Unable to delete container ${existing.containerid} as it is '
                'running'));
            printerr(
                'Delete all containers for ${image.imageid} and try again.');
            exit(1);
          }
        }
        existing.delete();
      }
    }
  }

  void createContainer(Image image, ConfigYaml config, {required bool debug}) {
    print('Creating container from Image ${image.fullname}.');

    final lines = <String>[];
    final progress = Progress(lines.add, stderr: lines.add);

    final volumes = StringBuffer();
    final provider = ContentProviders().getByName(config.contentProvider);
    if (provider == null) {
      throw ConfigurationException(
          'Unable to load the configured contentProvider: '
          '${config.contentProvider}');
    }
    for (final volume in provider.getVolumes()) {
      volumes.write(' -v ${volume.hostPath}:${volume.containerPath}');
    }

    if (Strings.isEmpty(config.authProvider)) {
      throw ConfigurationException("The AuthProvider hasn't been configured.");
    }
    final authProvider = AuthProviders().getByName(config.authProvider!);
    if (authProvider == null) {
      throw ConfigurationException(
          "The AuthProvider ${config.authProvider}hasn't been configured.");
    }
    final environments = authProvider.environment;

    final dnsProviderEnvs = StringBuffer();

    for (final env in environments) {
      dnsProviderEnvs.write(' --env=${env.name}=${env.value}');
    }

    'docker create'
            ' --name="nginx-le"'
            ' --env=${Environment.hostnameKey}=${config.hostname}'
            ' --env=${Environment.domainKey}=${config.domain}'
            ' --env=${Environment.tldKey}=${config.tld}'
            ' --env='
            '${Environment().productionKey}=${config.isProduction.toString()}'
            ' --env=${Environment.startPausedKey}=${config.startPaused}'
            ' --env=${Environment.authProviderKey}=${config.authProvider}'
            ' --env=${Environment.emailaddressKey}=${config.emailaddress}'
            ' --env=${Environment.smtpServerKey}=${config.smtpServer}'
            ' --env=${Environment.smtpServerPortKey}=${config.smtpServerPort}'
            ' --env=${Environment.debugKey}=$debug'
            ' --env=${Environment.domainWildcardKey}=${config.domainWildcard}'
            // be default try to auto acquire a certificate.
            ' --env=${Environment.autoAcquireKey}=true'
            '$dnsProviderEnvs'
            ' --net=host'
            ' --log-driver=journald'
            ' -v certificates:${CertbotPaths().letsEncryptRootPath}'
            '$volumes'
            ' ${config.image!.imageid}'
        .start(nothrow: true, progress: progress);

    if (progress.exitCode != 0) {
      printerr(red('docker create failed with exitCode ${progress.exitCode}'));
      lines.forEach(printerr);
      exit(1);
    } else {
      // only the first 12 characters are actually used to start/stop containers.
      final containerid = lines[0].substring(0, 12);

      if (Containers().findByContainerId(containerid) == null) {
        printerr(red('Docker failed to create the container!'));
        exit(1);
      } else {
        print(green('Container created.'));
        config.containerid = containerid;
      }
    }
    print('');

    final startMethod = ConfigYaml().startMethod;
    if (startMethod == ConfigYaml.startMethodNginxLe) {
      if (confirm('Would you like to start the container:',
          defaultValue: true)) {
        'docker start nginx-le'.run;
      } else {
        print(blue('Use ${orange('nginx-le start')} to start the container.'));
      }
    } else if (startMethod == ConfigYaml.startMethodDockerStart) {
      print(blue('Use your Dockerfile to start nginx-le.'));
    } else {
      // ConfigYaml.START_METHOD_DOCKER_COMPOSE
      print(blue('Use your docker-compose file to start nginx-le.'));
    }
  }

  void selectAuthProvider(ConfigYaml config) {
    final authProviders = AuthProviders().getValidProviders(config);

    var defaultProvider = AuthProviders().getByName(config.authProvider!);
    if (!authProviders.contains(defaultProvider)) {
      defaultProvider = authProviders[0];
    }

    print('');
    print(green('Select the Auth Provider'));
    final provider = menu<AuthProvider>(
        prompt: 'Content Provider:',
        options: authProviders,
        defaultOption: defaultProvider,
        format: (provider) => provider.summary);

    config.authProvider = provider.name;

    provider.promptForSettings(config);
  }

  void selectCertType(ConfigYaml config) {
    print(green('Only select wildcard if the system has multiple fqdns.'));

    const wildcard = 'Wildcard';
    final domainType = menu(
        prompt: 'Certificate Type',
        options: ['FQDN', wildcard],
        defaultOption: config.domainWildcard ? wildcard : 'FQDN');

    config.domainWildcard = domainType == wildcard;

    print('');
    print(green('During testing please select "staging"'));
    final certTypes = [
      ConfigYaml.certificateTypeProduction,
      ConfigYaml.certificateTypeStaging
    ];
    config.certificateType ??= ConfigYaml.certificateTypeStaging;
    final certificateType = menu(
        prompt: 'Certificate Type:',
        options: certTypes,
        defaultOption: config.certificateType);
    config.certificateType = certificateType;
  }

  void selectEmail(ConfigYaml config) {
    print('');
    print(green('Errors are notified via email'));
    final emailaddress = ask('Email Address:',
        defaultValue: config.emailaddress,
        validator: Ask.all([Ask.required, Ask.email]));
    config.emailaddress = emailaddress;

    final smtpServer = ask('SMTP Server:',
        defaultValue: config.smtpServer,
        validator: Ask.all([Ask.required, const AskFQDNOrLocalhost()]));
    config.smtpServer = smtpServer;

    final smtpServerPort = ask('SMTP Server port:',
        defaultValue: '${config.smtpServerPort}',
        validator:
            Ask.all([Ask.required, Ask.integer, Ask.valueRange(1, 65535)]));
    config.smtpServerPort = int.tryParse(smtpServerPort) ?? 25;
  }

  void selectTLD(ConfigYaml config) {
    print('');
    print(green('The servers top level domain (e.g. com.au)'));

    final tld = ask('TLD:', defaultValue: config.tld, validator: Ask.required);
    config.tld = tld;
  }

  void selectFQDN(ConfigYaml config) {
    print('');
    print(green("The server's FQDN (e.g. www.microsoft.com)"));
    final fqdn = ask('FQDN:',
        defaultValue: config.fqdn, validator: const AskFQDNOrLocalhost());
    config.fqdn = fqdn;
  }

  Image selectImage(ConfigYaml config) {
    print('');
    print(green('Select the image to utilise.'));
    const latest = 'onepub/nginx-le:latest';
    final images = Images()
        .images
        .where(
            (image) => image.repository == 'onepub' && image.name == 'nginx-le')
        .toList();
    final latestImage = Images().findByName(latest);
    Image downloadLatest;
    if (latestImage != null) {
      downloadLatest = Image.fromName(latest);
    } else {
      downloadLatest = Image(
          repositoryAndName: '',
          tag: '',
          imageid: 'Download'.padRight(12),
          created: '',
          size: '');
      images.insert(0, downloadLatest);
    }
    var image = menu<Image>(
        prompt: 'Image:',
        options: images,
        format: (image) =>
            '${image.imageid} - ${image.repository}/${image.name}:${image.tag}',
        defaultOption: config.image);
    config.image = image;

    if (image == downloadLatest) {
      print(orange('Downloading the latest image'));
      Images().pull(fullname: image.fullname);

      /// after pulling the image additional information will be available
      /// so replace the image with the fully detailed version.
      final _image = Images().findByName(latest);
      if (_image == null) {
        throw DockerException("The selected image $latest can't be found.");
      }
      image = _image;
    }
    return image;
  }

  void selectMode(ConfigYaml config) {
    print('');
    print(green('Select the visibility of your Web Server'));
    config.mode ??= ConfigYaml.modePrivate;
    final options = [ConfigYaml.modePublic, ConfigYaml.modePrivate];
    final mode = menu(
      prompt: 'Mode:',
      options: options,
      defaultOption: config.mode,
    );
    config.mode = mode;
  }

  void selectStartMode(ConfigYaml config) {
    print('');
    config.startPaused ??= false;

    config.startPaused = confirm(
        green('Start the container in Paused mode to diagnose problems'),
        defaultValue: config.startPaused);
  }

  void selectStartMethod(ConfigYaml config) {
    // ignore: unnecessary_statements
    config.startMethod ?? ConfigYaml.startMethodNginxLe;
    final startMethods = [
      ConfigYaml.startMethodNginxLe,
      ConfigYaml.startMethodDockerStart,
      ConfigYaml.startMethodDockerCompose
    ];

    print('');
    print(green('Select the method you will use to start Nginx-LE'));
    final startMethod = menu(
      prompt: 'Start Method:',
      options: startMethods,
      defaultOption: config.startMethod,
    );
    config.startMethod = startMethod;
  }

  /// Ask users where the website content is located.
  void selectContentProvider(ConfigYaml config) {
    final contentProviders = ContentProviders().providers;

    final defaultProvider =
        ContentProviders().getByName(config.contentProvider);
    print('');
    print(green('Select the Content Provider'));
    final provider = menu<ContentProvider>(
        prompt: 'Content Provider:',
        options: contentProviders,
        defaultOption: defaultProvider,
        format: (provider) =>
            '${provider.name.padRight(12)} - ${provider.summary}');

    config.contentProvider = provider.name;

    provider.promptForSettings();
  }

  void selectContainer(ConfigYaml config) {
    /// try for the default container name.
    var containers = Containers()
        .containers()
        .where((container) => container.name == 'nginx-le')
        .toList();

    if (containers.isEmpty) {
      containers = Containers().containers();
    }

    final defaultOption = Containers().findByContainerId(config.containerid!);

    if (containers.isEmpty) {
      if (config.startMethod == ConfigYaml.startMethodDockerCompose) {
        printerr(
            red('Please run docker-compose up before running nginx-le config'));
        exit(-1);
      } else {
        printerr(red("ERROR: something went wrong as we couldn't find "
            'the nginx-le docker container'));
        exit(-1);
      }
    } else if (containers.length == 1) {
      config.containerid = containers[0].containerid;
    } else {
      print(green('Select the docker container running nginx-le'));
      final container = menu<Container>(
          prompt: 'Select Container:',
          options: containers,
          defaultOption: defaultOption,
          format: (container) =>
              '${container.name.padRight(30)} ${container.image?.fullname}');
      config.containerid = container.containerid;
    }
  }
}

void showUsage(ArgParser parser) {
  print(parser.usage);
  exit(-1);
}
