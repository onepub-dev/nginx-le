import 'dart:io';

import 'package:dshell/dshell.dart' as d;
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:settings_yaml/settings_yaml.dart';

class ConfigYaml {
  static final _self = ConfigYaml._internal();
  static const configDir = '.nginx-le';
  static const configFile = 'settings.yaml';

  // static const CONTENT_SOURCE_PATH = 'Simple wwwroot';
  // static const CONTENT_SOURCE_LOCATION = 'Locations';
  // static const CONTENT_SOURCE_TOMCAT = 'Tomcat';

  static const MODE_PUBLIC = 'public';
  static const MODE_PRIVATE = 'private';

  static const CERTIFICATE_TYPE_PRODUCTION = 'production';
  static const CERTIFICATE_TYPE_STAGING = 'staging';

  static const START_METHOD_NGINX_LE = 'nginx-le';
  static const START_METHOD_DOCKER_START = 'docker-start';
  static const START_METHOD_DOCKER_COMPOSE = 'docker-compose';

  SettingsYaml settings;

  /// keys
  static const START_METHOD_KEY = 'start-method';
  static const MODE_KEY = 'mode';
  static const HOSTNAME_KEY = 'host';
  static const FQDN_KEY = 'fqdn';
  static const TLD_KEY = 'tld';
  static const IMAGE = 'image';
  static const CONTAINERID = 'containerid';
  static const EMAILADDRESS = 'emailaddress';
  static const DNSPROVIDER = 'dns_provider';
  static const CERTIFICATE_TYPE = 'certificate_type';
  static const HOST_INCLUDE_PATH = 'host_include_path';
  static const CONTENT_PROVIDER = 'content_provider';
  static const WWW_ROOT = 'www_root';

  // defaults:
  static const DEFAULT_HOST_INCLUDE_PATH = '/opt/nginx/include';

  String startMethod;
  String mode;
  String fqdn;
  String tld;
  Image image;

  String certificateType;

  /// the name of the container to run
  String containerid;
  String emailaddress;

  String dnsProvider;

  // The name of the selected [ContentProvider]
  String contentProvider;

  /// host path which is mounted into ngix and contains .location and .upstream files from.
  String _hostIncludePath;

  /// Name Cheap settings
  static const NAMECHEAP_PROVIDER = 'namecheap';
  static const NAMECHEAP_KEY = 'apiKey';
  static const NAMECHEAP_USERNAME = 'apiUsername';

  String namecheap_apikey;
  String namecheap_apiusername;

  factory ConfigYaml() => _self;

  ConfigYaml._internal() {
    if (!d.exists(d.dirname(configPath))) {
      d.createDir(d.dirname(configPath), recursive: true);
    }

    settings = SettingsYaml.load(filePath: configPath);
    startMethod = settings[START_METHOD_KEY] as String;
    mode = settings[MODE_KEY] as String;
    fqdn = settings[FQDN_KEY] as String;
    tld = settings[TLD_KEY] as String;
    image = Images().findByImageId(settings[IMAGE] as String);
    certificateType = settings[CERTIFICATE_TYPE] as String;
    emailaddress = settings[EMAILADDRESS] as String;
    containerid = settings[CONTAINERID] as String;
    dnsProvider = settings[DNSPROVIDER] as String;
    contentProvider = settings[CONTENT_PROVIDER] as String;
    _hostIncludePath = settings[HOST_INCLUDE_PATH] as String;

    if (dnsProvider == NAMECHEAP_PROVIDER) {
      namecheap_apikey = settings[NAMECHEAP_KEY] as String;
      namecheap_apiusername = settings[NAMECHEAP_USERNAME] as String;
    }
  }

  ///
  bool get isConfigured => d.exists(configPath) && fqdn != null;

  bool get isStaging => certificateType == ConfigYaml.CERTIFICATE_TYPE_STAGING;

  bool get isModePrivate => mode == MODE_PRIVATE;

  String get hostIncludePath {
    _hostIncludePath ??= DEFAULT_HOST_INCLUDE_PATH;
    if (_hostIncludePath.isEmpty) {
      _hostIncludePath = DEFAULT_HOST_INCLUDE_PATH;
    }
    return _hostIncludePath;
  }

  String get domain {
    if (fqdn == null) return '';

    if (fqdn.contains('.')) {
      /// return everything but the first part (hostname).
      return fqdn.split('.').sublist(1).join('.');
    }

    return fqdn;
  }

  String get hostname {
    if (fqdn == null) return '';

    if (fqdn.contains('.')) {
      return fqdn.split('.')[0];
    }

    return fqdn;
  }

  set hostIncludePath(String hostIncludePath) {
    _hostIncludePath = hostIncludePath;
  }

  void save() {
    settings[START_METHOD_KEY] = startMethod;
    settings[MODE_KEY] = mode;
    settings[FQDN_KEY] = fqdn;
    settings[TLD_KEY] = tld;
    settings[IMAGE] = '${image?.imageid}';
    settings[CERTIFICATE_TYPE] = certificateType;
    settings[EMAILADDRESS] = emailaddress;
    settings[CONTAINERID] = containerid;
    settings[DNSPROVIDER] = dnsProvider;
    settings[CONTENT_PROVIDER] = contentProvider;
    settings[HOST_INCLUDE_PATH] = hostIncludePath;

    if (dnsProvider == NAMECHEAP_PROVIDER) {
      settings[NAMECHEAP_KEY] = namecheap_apikey;
      settings[NAMECHEAP_USERNAME] = namecheap_apiusername;
    }
    settings.save();
  }

  String get configPath {
    return d.join(d.HOME, configDir, configFile);
  }

  void validate(void Function() showUsage) {
    if (!isConfigured) {
      printerr(red(
          "A saved configuration doesn't exist. You must use first run 'nginx-le config."));
      showUsage();
    }

    if (image == null) {
      printerr(red(
          "Your configuration is in an inconsistent state. (image is null). Run 'nginx-le config'."));
      showUsage();
    }

    if (!Containers().existsByContainerId(containerid)) {
      printerr(red('The ngnix-le container ${containerid} no longer exists.'));
      printerr(red('  Run nginx-le config to change the container.'));
      exit(1);
    }
    if (!Images().existsByImageId(imageid: image.imageid)) {
      printerr(red('The ngnix-le image ${image.imageid} no longer exists.'));
      printerr(red('  Run nginx-le config to change the image.'));
      exit(1);
    }
  }
}
