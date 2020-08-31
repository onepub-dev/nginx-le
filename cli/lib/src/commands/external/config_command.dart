import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le/src/content_providers/content_provider.dart';
import 'package:nginx_le/src/content_providers/content_providers.dart';
import 'package:nginx_le/src/util/ask_fqdn_validator.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class ConfigCommand extends Command<void> {
  @override
  String get description => 'Allows you to configure your Nginx-LE server';

  @override
  String get name => 'config';

  ConfigCommand() {
    /// argParser.addOption('template')
    argParser.addFlag('debug',
        defaultsTo: false,
        negatable: false,
        abbr: 'd',
        help: 'Outputs additional logging information and puts the container into debug mode');
  }

  @override
  void run() {
    var debug = argResults['debug'] as bool;
    Settings().setVerbose(enabled: debug);

    var config = ConfigYaml();

    selectStartMethod(config);

    selectFQDN(config);

    selectTLD(config);

    selectEmail(config);

    selectMode(config);
    selectCertType(config);

    if (config.isModePrivate || config.wildcard) {
      selectDNSProvider(config);
    } else {
      config.certbothAuthProvider = null;
    }

    selectContentProvider(config);

    var containerName = 'nginx-le';

    var image = selectImage(config);

    config.save();
    print('Configuration saved.');

    var provider = ContentProviders().getByName(config.contentProvider);

    provider.createLocationFile();
    provider.createUpstreamFile();

    if (config.startMethod != ConfigYaml.START_METHOD_DOCKER_COMPOSE) {
      deleteOldContainers(containerName, image);
      createContainer(image, config, debug);
    } else {
      selectContainer(config);
    }

    /// save the new container id.
    config.save();
  }

  void deleteOldContainers(String containerName, Image image) {
    var existing = Containers().findByName(containerName);

    if (existing != null) {
      print('A container with the name $containerName already exists');
      if (!confirm('Do you want to delete the older container and create one with the new settings?')) {
        print(orange('Container does not reflect your new settings!'));
        exit(-1);
      } else {
        if (existing.isRunning) {
          print('The old container is running. To delete the container it must be stopped.');
          if (confirm('Do you want the container ${existing.containerid} stopped?')) {
            existing.stop();
          } else {
            printerr(red('Unable to delete container ${existing.containerid} as it is running'));
            printerr('Delete all containers for ${image.imageid} and try again.');
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
    var progress = Progress((line) => lines.add(line), stderr: (line) => lines.add(line));

    var volumes = '';
    var provider = ContentProviders().getByName(config.contentProvider);
    for (var volume in provider.getVolumes()) {
      volumes += ' -v ${volume.hostPath}:${volume.containerPath}';
    }

    var authProvider = AuthProviders().getByName(config.certbothAuthProvider);
    var environments = authProvider.environment;

    var dnsProviderEnvs = '';

    for (var env in environments) {
      dnsProviderEnvs += ' --env=${env.name}=${env.value}';
    }

    var cmd = 'docker create'
        ' --name="nginx-le"'
        ' --env=HOSTNAME=${config.hostname}'
        ' --env=DOMAIN=${config.domain}'
        ' --env=TLD=${config.tld}'
        ' --env=MODE=${config.mode}'
        ' --env=CERTBOT_AUTH_PROVIDER=${config.certbothAuthProvider}'
        ' --env=EMAIL_ADDRESS=${config.emailaddress}'
        ' --env=SMTP_SERVER=${config.smtpServer}'
        ' --env=SMTP_SERVER_PORT=${config.smtpServerPort}'
        ' --env=DEBUG=$debug'
        ' --env=DOMAIN_WILDCARD=${config.wildcard}'
        ' --env=AUTO_ACQUIRE=true' // be default try to auto acquire a certificate.
        '$dnsProviderEnvs'
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
        print(green('Container created.'));
        config.containerid = containerid;
      }
    }
    print('');

    var startMethod = ConfigYaml().startMethod;
    if (startMethod == ConfigYaml.START_METHOD_NGINX_LE) {
      print(blue('Use nginx-le start to start the container'));
    } else if (startMethod == ConfigYaml.START_METHOD_DOCKER_START) {
      print(blue('Use your Dockerfile to start nginx-le'));
    } else {
      // ConfigYaml.START_METHOD_DOCKER_COMPOSE
      print(blue('Use your docker-compose file to start nginx-le.'));
    }
  }

  void selectDNSProvider(ConfigYaml config) {
    var authProviders = DnsAuthProviders().providers;

    var defaultProvider = DnsAuthProviders().getByName(config.certbothAuthProvider);
    print('');
    print(green('Select the DNS Auth Provider'));
    var provider = menu<AuthProvider>(
        prompt: 'Content Provider:',
        options: authProviders,
        defaultOption: defaultProvider,
        format: (provider) => '${provider.name.padRight(12)} - ${provider.summary}');

    config.certbothAuthProvider = provider.name;

    provider.promptForSettings(config);
  }

  void selectCertType(ConfigYaml config) {
    print(green('Only select wildcard if the system has multiple fqdns.'));

    const wildcard = 'Wildcard';
    var domainType =
        menu(prompt: 'Domain Type', options: ['FQDN', wildcard], defaultOption: config.wildcard ? wildcard : 'FQDN');

    config.wildcard = (domainType == wildcard);

    print('');
    print(green('During testing please select "staging"'));
    var certTypes = [ConfigYaml.CERTIFICATE_TYPE_PRODUCTION, ConfigYaml.CERTIFICATE_TYPE_STAGING];
    config.certificateType ??= ConfigYaml.CERTIFICATE_TYPE_STAGING;
    var certificateType = menu(prompt: 'Certificate Type:', options: certTypes, defaultOption: config.certificateType);
    config.certificateType = certificateType;
  }

  void selectEmail(ConfigYaml config) {
    print('');
    print(green('Errors are notified via email'));
    var emailaddress = ask('Email Address:',
        defaultValue: config.emailaddress, validator: AskMultiValidator([Ask.required, Ask.email]));
    config.emailaddress = emailaddress;

    var smtpServer =
        ask('SMTP Server:', defaultValue: config.smtpServer, validator: AskMultiValidator([Ask.required, Ask.fqdn]));
    config.smtpServer = smtpServer;

    var smtpServerPort = ask('SMTP Server port:',
        defaultValue: '${config.smtpServerPort}',
        validator: AskMultiValidator([Ask.required, Ask.integer, AskRange(1, 65535)]));
    config.smtpServerPort = int.tryParse(smtpServerPort) ?? 25;
  }

  void selectTLD(ConfigYaml config) {
    print('');
    print(green('The servers top level domain (e.g. com.au)'));

    var tld = ask('TLD:', defaultValue: config.tld, validator: AskMultiValidator([Ask.required]));
    config.tld = tld;
  }

  void selectFQDN(ConfigYaml config) {
    print('');
    print(green("The server's FQDN (e.g. www.microsoft.com)"));
    var fqdn = ask('FQDN:', defaultValue: config.fqdn, validator: AskFQDNOrLocalhost());
    config.fqdn = fqdn;
  }

  Image selectImage(ConfigYaml config) {
    print('');
    print(green('Select the image to utilise.'));
    var latest = 'noojee/nginx-le:latest';
    var images = Images().images.where((image) => image.repository == 'noojee' && image.name == 'nginx-le').toList();
    var latestImage = Images().findByFullname(latest);
    var downloadLatest = Image.fromName(latest);
    if (latestImage == null) {
      downloadLatest.imageid = 'Download'.padRight(12);
      images.insert(0, downloadLatest);
    }
    var image = menu<Image>(
        prompt: 'Image:',
        options: images,
        format: (image) => '${image.imageid} - ${image.repository}/${image.name}:${image.tag}',
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
  void selectContentProvider(ConfigYaml config) {
    var contentProviders = ContentProviders().providers;

    var defaultProvider = ContentProviders().getByName(config.contentProvider);
    print('');
    print(green('Select the Content Provider'));
    var provider = menu<ContentProvider>(
        prompt: 'Content Provider:',
        options: contentProviders,
        defaultOption: defaultProvider,
        format: (provider) => '${provider.name.padRight(12)} - ${provider.summary}');

    config.contentProvider = provider.name;

    provider.promptForSettings();
  }

  void selectContainer(ConfigYaml config) {
    /// try for the default container name.
    var containers = Containers().containers().where((container) => container.names == 'nginx-le').toList();

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
          format: (container) => '${container.names.padRight(30)} ${container.image?.fullname}');
      config.containerid = container.containerid;
    }
  }
}

void showUsage(ArgParser parser) {
  print(parser.usage);
  exit(-1);
}
