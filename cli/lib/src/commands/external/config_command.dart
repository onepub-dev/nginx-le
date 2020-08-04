import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/builders/locations/wwwroot.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:uuid/uuid.dart';

/// Starts nginx and the certbot scheduler.
class ConfigCommand extends Command<void> {
  @override
  String get description => 'Allows you to configure your Nginx-LE server';

  @override
  String get name => 'config';

  ConfigCommand() {
    argParser.addFlag('debug',
        defaultsTo: false,
        negatable: false,
        abbr: 'd',
        help: 'Outputs additional logging information');
  }

  @override
  void run() {
    var debug = argResults['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();

    selectStartMethod(config);

    selectMode(config);

    selectHost(config);
    selectDomain(config);

    selectTLD(config);

    selectEmailAddress(config);

    selectCertType(config);

    if (config.isModePrivate) {
      selectDNSProvider(config);
    } else {
      config.dnsProvider = null;
    }

    getContentSource(config);

    var containerName = 'nginx-le';

    var image = selectImage(config);
    if (config.startMethod != ConfigYaml.START_METHOD_DOCKER_COMPOSE) {
      deleteOldContainers(containerName, image);
      createContainer(image, config, debug);
    } else {
      selectContainer(config);
    }

    config.save();
    print('Configuration saved.');
  }

  void deleteOldContainers(String containerName, Image image) {
    var existing = Containers().findByName(containerName);

    if (existing != null) {
      print('A containers with the name $containerName already exists');
      if (!confirm(
          prompt:
              'Do you want to delete the older container and create one with the new settings?')) {
        print('Settings not saved. config command aborted');
        exit(-1);
      } else {
        if (existing.isRunning) {
          print(
              'The old container is running. To delete the container it must be stopped.');
          if (confirm(
              prompt:
                  'Do you want the container ${existing.containerid} stopped?')) {
            existing.stop();
          } else {
            printerr(red(
                'Unable to delete container ${existing.containerid} as it is running'));
            printerr(
                'Delete all containers for ${image.imageid} and try again.');
            exit(1);
          }
        }
        existing.delete();
      }
    }
  }

  void createContainer(Image image, ConfigYaml config, bool debug) {
    print('Creating container from Image ${image.fullname}.');

    var lines = <String>[];
    var progress =
        Progress((line) => lines.add(line), stderr: (line) => lines.add(line));

    var volumes = '';

    if (config.contentSourceType == ConfigYaml.CONTENT_SOURCE_PATH) {
      volumes += ' -v ${config.wwwRoot}:${config.wwwRoot}';
    }
    volumes += ' -v ${config.hostIncludePath}:${Nginx.containerIncludePath}';

    var cmd = 'docker create'
        ' --name="nginx-le"'
        ' --env=HOSTNAME=${config.hostname}'
        ' --env=DOMAIN=${config.domain}'
        ' --env=TLD=${config.tld}'
        ' --env=MODE=${config.mode}'
        ' --env=EMAIL_ADDRESS=${config.emailaddress}'
        ' --env=DEBUG=$debug'
        ' --net=host'
        ' --log-driver=journald'
        ' -v certificates:${Certbot.letsEncryptRootPath}'
        '$volumes'
        ' ${config.image.imageid}';

    cmd.start(nothrow: true, progress: progress);
    Containers().flushCache();

    if (progress.exitCode != 0) {
      printerr(red('docker create failed with exitCode ${progress.exitCode}'));
      lines.forEach(printerr);
      exit(1);
    } else {
      // only the first 12 characters are actually used to start/stop containers.
      var containerid = lines[0].substring(0, 12);

      if (Containers().findByContainerId(containerid) == null) {
        printerr(red('Docker failed to create the container!'));
        exit(1);
      } else {
        print('Container created');
        config.containerid = containerid;
      }
    }
  }

  void selectDNSProvider(ConfigYaml config) {
    config.dnsProvider = ConfigYaml.NAMECHEAP_PROVIDER;

    var namecheap_username = ask(
        prompt: 'NameCheap API Username:',
        defaultValue: config.namecheap_apiusername,
        validator: Ask.required);
    config.namecheap_apiusername = namecheap_username;

    var namecheap_apikey = ask(
        prompt: 'NameCheap API Key:',
        defaultValue: config.namecheap_apikey,
        hidden: true,
        validator: Ask.required);
    config.namecheap_apikey = namecheap_apikey;
  }

  void selectCertType(ConfigYaml config) {
    print('');
    print(green('During testing please select "staging"'));
    var certTypes = ['production', 'staging'];
    var certificateType = menu(
        prompt: 'Certificate Type:',
        options: certTypes,
        defaultOption: 'staging');
    config.certificateType = certificateType;
  }

  void selectEmailAddress(ConfigYaml config) {
    var emailaddress = ask(
        prompt: 'Email Address:',
        defaultValue: config.emailaddress,
        validator: Ask.email);
    config.emailaddress = emailaddress;
  }

  void selectTLD(ConfigYaml config) {
    print('');
    print(green('The servers top level domain (e.g. com.au)'));

    var tld = ask(
        prompt: 'TLD:',
        defaultValue: config.tld,
        validator: AskMultiValidator([Ask.required, Ask.alphaNumeric]));
    config.tld = tld;
  }

  void selectHost(ConfigYaml config) {
    print('');
    print(green('The servers hostname (e.g. www)'));
    var hostname = ask(
        prompt: 'Hostname:',
        defaultValue: config.hostname,
        validator: Ask.alphaNumeric);
    config.hostname = hostname;
  }

  void selectDomain(ConfigYaml config) {
    print('');
    print(green('The servers domain (e.g. microsoft.com.au)'));

    var domain = ask(
        prompt: 'Domain:', defaultValue: config.domain, validator: Ask.fqdn);
    config.domain = domain;
  }

  Image selectImage(ConfigYaml config) {
    print('');
    print(green('Select the image to utilise.'));
    var latest = 'noojee/nginx-le:latest';
    var images = Images()
        .images
        .where(
            (image) => image.repository == 'noojee' && image.name == 'nginx-le')
        .toList();
    var latestImage = Images().findByFullname(latest);
    var downloadLatest = Image.fromName(latest);
    if (latestImage == null) {
      downloadLatest.imageid = 'Download'.padRight(12);
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
      Images().flushCache();
      image = Images().findByFullname(latest);
    }
    return image;
  }

  void selectMode(ConfigYaml config) {
    print('');
    print(green('Select the visibility of your Web Server'));
    config.mode ??= ConfigYaml.MODE_PRIVATE;
    var options = [ConfigYaml.MODE_PUBLIC, ConfigYaml.MODE_PRIVATE];
    var mode = menu(
      prompt: 'Mode:',
      options: options,
      defaultOption: config.mode,
    );
    config.mode = mode;
  }

  void selectStartMethod(ConfigYaml config) {
    config.startMethod ?? ConfigYaml.START_METHOD_NGINX_LE;
    var startMethods = [
      ConfigYaml.START_METHOD_NGINX_LE,
      ConfigYaml.START_METHOD_DOCKER_START,
      ConfigYaml.START_METHOD_DOCKER_COMPOSE
    ];

    print('');
    print(green('Select the method you will use to start Nginx-LE'));
    var startMethod = menu(
      prompt: 'Start Method:',
      options: startMethods,
      defaultOption: config.startMethod,
    );
    config.startMethod = startMethod;
  }

  /// Ask users where the website content is located.
  void getContentSource(ConfigYaml config) {
    var contentSource = <String>[
      ConfigYaml.CONTENT_SOURCE_PATH,
      ConfigYaml.CONTENT_SOURCE_LOCATION
    ];
    print('');
    print(green('Select how the Content is to be served'));
    var selection = menu(
        prompt: 'Content Source:',
        options: contentSource,
        defaultOption: config.contentSourceType);

    if (selection == ConfigYaml.CONTENT_SOURCE_PATH) {
      selectSourcePath(config);
      config.contentSourceType = ConfigYaml.CONTENT_SOURCE_PATH;
    } else {
      setIncludePath(config);
      config.contentSourceType = ConfigYaml.CONTENT_SOURCE_LOCATION;
    }
  }

  void selectSourcePath(ConfigYaml config) {
    var valid = false;
    String wwwroot;
    do {
      /// wwwroot
      var defaultPath =
          config.wwwRoot ?? WwwRoot(config.hostIncludePath).preferredHostPath;
      print('');
      print(green('Path to static web content'));
      wwwroot =
          ask(prompt: 'Path (on host) to wwwroot', defaultValue: defaultPath);
      if (!exists(wwwroot)) {
        print(red('The path $wwwroot does not exist.'));
        if (confirm(prompt: 'Create $wwwroot?')) {
          if (isWritable(findParent(wwwroot))) {
            createDir(wwwroot, recursive: true);
          } else {
            'sudo mkdir -p $wwwroot'.run;
          }
          valid = true;
        }
      } else {
        valid = true;
      }
    } while (!valid);

    valid = false;

    do {
      /// write out the location file
      var wwwBuilder = WwwRoot(wwwroot);
      var locationConfig = wwwBuilder.build();

      if (config.wwwRoot != null) {
        backupOldWwwLocation(config, locationConfig);
      }

      if (!isWritable(findParent(wwwBuilder.hostLocationConfigPath))) {
        var tmp = FileSync.tempFile();
        tmp.write(locationConfig);
        'sudo mv $tmp ${wwwBuilder.hostLocationConfigPath}'.run;
      } else {
        wwwBuilder.hostLocationConfigPath.write(locationConfig);
      }

      config.wwwRoot = wwwroot;
      valid = true;
    } while (!valid);
  }

  void backupOldWwwLocation(ConfigYaml config, String newLocationConfig) {
    var oldConfig = WwwRoot(config.wwwRoot);
    if (!exists(oldConfig.hostLocationConfigPath)) return; // nothing to backup
    var existingLocationConfig =
        read(oldConfig.hostLocationConfigPath).toList().join('\n');
    if (existingLocationConfig != newLocationConfig) {
      // looks like the user manually changed the contents of the file.
      var backup = '${oldConfig.hostLocationConfigPath}.bak';
      if (exists(backup)) {
        var target = '$backup.${Uuid().v4()}';
        if (!isWritable(backup)) {
          'sudo mv $backup $target'.run;
        } else {
          move(backup, '$backup.${Uuid().v4()}');
        }
      }

      if (!isWritable(dirname(backup))) {
        'sudo cp ${oldConfig.hostLocationConfigPath} $backup'.run;
      } else {
        copy(oldConfig.hostLocationConfigPath, backup);
      }

      print(
          'Your original location file ${oldConfig.hostLocationConfigPath} has been backed up to $backup');
    }
  }

  void setIncludePath(ConfigYaml config) {
    var valid = false;
    String hostIncludePath;
    do {
      print('');
      print('${green('Location of nginx include files')}');
      hostIncludePath = ask(
          prompt:
              'Include directory (on host) for `.location` and `.upstream` files:',
          defaultValue: config.hostIncludePath,
          validator: Ask.required);

      createPath(hostIncludePath);

      valid = true;
    } while (!valid);

    config.hostIncludePath = hostIncludePath;
  }

  void createPath(String path) {
    if (!exists(path)) {
      if (isWritable(findParent(path))) {
        createDir(path, recursive: true);
      } else {
        'sudo mkdir -p $path'.run;
      }
    }
  }

  /// climb the tree until we find a parent directory that exists.
  /// If path exists we will return it.
  String findParent(String path) {
    var current = path;
    while (!exists(current)) {
      current = dirname(current);
    }
    return current;
  }

  void selectContainer(ConfigYaml config) {
    /// try for the default container name.
    var containers = Containers()
        .containers()
        .where((container) => container.names == 'nginx-le')
        .toList();

    if (containers.isEmpty) {
      containers = Containers().containers();
    }

    var defaultOption = Containers().findByContainerId(config.containerid);

    if (containers.length == 1) {
      config.containerid = containers[0].containerid;
    } else {
      print(green('Select the docker container running nginx-le'));
      var container = menu<Container>(
          prompt: 'Select Container:',
          options: containers,
          defaultOption: defaultOption,
          format: (container) =>
              '${container.names.padRight(30)} ${container.image?.fullname}');
      config.containerid = container.containerid;
    }
  }
}

void showUsage(ArgParser parser) {
  print(parser.usage);
  exit(-1);
}
