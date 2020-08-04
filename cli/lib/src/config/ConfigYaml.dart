import 'dart:io';

import 'package:dshell/dshell.dart' as d;
import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:yaml/yaml.dart';

class ConfigYaml {
  static final _self = ConfigYaml._internal();
  static const configDir = '.nginx-le';
  static const configFile = 'settings.yaml';

  static const CONTENT_SOURCE_PATH = 'Simple wwwroot';
  static const CONTENT_SOURCE_LOCATION = 'Locations';

  static const MODE_PUBLIC = 'public';
  static const MODE_PRIVATE = 'private';

  static const START_METHOD_NGINX_LE = 'nginx-le';
  static const START_METHOD_DOCKER_START = 'docker-start';
  static const START_METHOD_DOCKER_COMPOSE = 'docker-compose';

  YamlDocument _document;

  /// keys
  static const START_METHOD_KEY = 'start-method';
  static const MODE_KEY = 'mode';
  static const HOSTNAME_KEY = 'host';
  static const DOMAIN_KEY = 'domain';
  static const TLD_KEY = 'tld';
  static const IMAGE = 'image';
  static const CONTAINERID = 'containerid';
  static const EMAILADDRESS = 'emailaddress';
  static const DNSPROVIDER = 'dns_provider';
  static const CERTIFICATE_TYPE = 'certificate_type';
  static const HOST_INCLUDE_PATH = 'host_include_path';
  static const CONTENT_SOURCE = 'content_source';
  static const WWW_ROOT = 'www_root';

  // defaults:
  static const DEFAULT_HOST_INCLUDE_PATH = '/opt/nginx/include';

  String startMethod;
  String mode;
  String hostname;
  String domain;
  String tld;
  Image image;

  String certificateType;

  /// the name of the container to run
  String containerid;
  String emailaddress;

  String dnsProvider;

  // The type of content source (wwwroot or location)
  String contentSourceType;

  /// host path which is mounted into ngix and contains .location and .upstream files from.
  String _hostIncludePath;

  /// If the user chose a content source of CONTENT_SOURCE_PATH this contains the path to the
  /// wwwroot file the selected during configuration.
  String wwwRoot;

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

    if (d.exists(configPath)) {
      var contents = d.waitForEx<String>(File(configPath).readAsString());
      _document = _load(contents);
      startMethod = getValue(START_METHOD_KEY);
      mode = getValue(MODE_KEY);
      hostname = getValue(HOSTNAME_KEY);
      domain = getValue(DOMAIN_KEY);
      tld = getValue(TLD_KEY);
      image = Images().findByImageId(getValue(IMAGE));
      certificateType = getValue(CERTIFICATE_TYPE);
      emailaddress = getValue(EMAILADDRESS);
      containerid = getValue(CONTAINERID);
      dnsProvider = getValue(DNSPROVIDER);
      contentSourceType = getValue(CONTENT_SOURCE);
      _hostIncludePath = getValue(HOST_INCLUDE_PATH);
      wwwRoot = getValue(WWW_ROOT);

      if (dnsProvider == NAMECHEAP_PROVIDER) {
        var namecheapMap = getMap(NAMECHEAP_PROVIDER);
        if (namecheapMap != null) {
          namecheap_apikey = namecheapMap[NAMECHEAP_KEY] as String;
          namecheap_apiusername = namecheapMap[NAMECHEAP_USERNAME] as String;
        }
      }
    }
  }

  ///
  bool get isConfigured => d.exists(configPath) && domain != null;

  bool get isStaging => certificateType == 'staging';

  bool get isModePrivate => mode == MODE_PRIVATE;

  String get hostIncludePath {
    _hostIncludePath ??= DEFAULT_HOST_INCLUDE_PATH;
    if (_hostIncludePath.isEmpty) {
      _hostIncludePath = DEFAULT_HOST_INCLUDE_PATH;
    }
    return _hostIncludePath;
  }

  set hostIncludePath(String hostIncludePath) {
    _hostIncludePath = hostIncludePath;
  }

  YamlDocument _load(String content) {
    return loadYamlDocument(content);
  }

  void save() {
    configPath.write('# Nginx-LE configuration file');
    configPath.append('$START_METHOD_KEY: $startMethod');
    configPath.append('$MODE_KEY: $mode');
    configPath.append('$HOSTNAME_KEY: $hostname');
    configPath.append('$DOMAIN_KEY: $domain');
    configPath.append('$TLD_KEY: $tld');
    configPath.append('$IMAGE: ${image?.imageid}');
    configPath.append('$CERTIFICATE_TYPE: ${certificateType}');
    configPath.append('$EMAILADDRESS: $emailaddress');
    configPath.append('$CONTAINERID: $containerid');
    configPath.append('$DNSPROVIDER: $dnsProvider');
    configPath.append('$CONTENT_SOURCE: $contentSourceType');
    configPath.append('$HOST_INCLUDE_PATH: $hostIncludePath');
    configPath.append('$WWW_ROOT: $wwwRoot');

    if (dnsProvider == NAMECHEAP_PROVIDER) {
      configPath.append('$NAMECHEAP_PROVIDER:');
      configPath.append('  $NAMECHEAP_KEY: $namecheap_apikey');
      configPath.append('  $NAMECHEAP_USERNAME: $namecheap_apiusername');
    }
  }

  String get configPath {
    return d.join(d.HOME, configDir, configFile);
  }

  /// reads the value of a top level [key].
  ///
  String getValue(String key) {
    if (_document.contents.value == null) {
      return null;
    } else {
      return _document.contents.value[key] as String;
    }
  }

  /// returns a list of elements attached to [key].
  YamlList getList(String key) {
    if (_document.contents.value == null) {
      return null;
    } else {
      return _document.contents.value[key] as YamlList;
    }
  }

  /// returns the map of elements attached to [key].
  YamlMap getMap(String key) {
    if (_document.contents.value == null) {
      return null;
    } else {
      return _document.contents.value[key] as YamlMap;
    }
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
