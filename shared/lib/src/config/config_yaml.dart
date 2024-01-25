/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'dart:io';

import 'package:dcli/dcli.dart' as d;
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:path/path.dart' as path;
import 'package:settings_yaml/settings_yaml.dart';

import '../../nginx_le_shared.dart';

class ConfigYaml {
  factory ConfigYaml() => _self;

  ConfigYaml._internal() {
    if (!d.exists(path.dirname(configPath))) {
      d.createDir(path.dirname(configPath), recursive: true);
    }

    settings = SettingsYaml.load(pathToSettings: configPath);
    startMethod = settings[startMethodKey] as String?;
    mode = settings[modeKey] as String?;
    startPaused = settings[Environment.startPausedKey] as bool?;
    fqdn = settings[fqdnKey] as String?;
    aliases = settings[aliasesKey] as String?;
    tld = settings[tldKey] as String?;
    image = Images().findByImageId((settings[imageKey] as String?)!);
    certificateType = settings[certificateTypeKey] as String?;
    emailaddress = settings[emailAddressKey] as String?;
    containerid = settings[containerIDKey] as String?;
    authProvider = settings[authProviderKey] as String?;
    contentProviders = settings[contentProviderKey] as String?;
    _hostIncludePath = settings[hostIncludePathKey] as String?;

    smtpServer = settings[Environment.smtpServerKey] as String?;
    smtpServerPort = settings[Environment.smtpServerPortKey] as int? ?? 25;

    /// If true we are using a wildcard dns (e.g. *.squarephone.biz)
    domainWildcard =
        (settings[Environment.domainWildcardKey] as bool?) ?? false;
  }

  static final _self = ConfigYaml._internal();
  static const configDir = '.nginx-le';
  static const configFile = 'settings.yaml';
  static const modePublic = 'public';
  static const modePrivate = 'private';
  static const certificateTypeProduction = 'production';
  static const certificateTypeStaging = 'staging';

  static const startMethodNginxLe = 'nginx-le';
  static const startMethodDockerStart = 'docker start/run';
  static const startMethodDockerCompose = 'docker-compose';

  late SettingsYaml settings;

  /// keys
  static const startMethodKey = 'start-method';
  static const startPausedKey = 'start-paused';
  static const modeKey = 'mode';
  static const hostnameKey = 'host';
  static const fqdnKey = 'fqdn';
  static const aliasesKey = 'aliases';
  static const tldKey = 'tld';
  static const imageKey = 'image';
  static const containerIDKey = 'containerid';
  static const emailAddressKey = 'emailaddress';
  static const certificateTypeKey = 'certificate_type';
  static const hostIncludePathKey = 'host_include_path';
  static const contentProviderKey = 'content_provider';
  static const authProviderKey = 'auth_provider';
  static const wwwRootKey = 'www_root';

  static const smtpServerKey = 'smtp_server';
  static const smtpServerPortKey = 'smtp_server_port';
  static const domainWildcardKey = 'domain_wildcard';

  // defaults:
  static const deafultHostIncludePathTo = '/opt/nginx/include';

  String? startMethod;
  String? mode;
  bool? startPaused;
  String? fqdn;

  /// List of alternate fqdns that the cert will validate.
  String? aliases;
  String? tld;
  Image? image;

  String? certificateType;

  /// the name of the container to run
  String? containerid;

  /// email
  String? emailaddress;
  String? smtpServer;
  int smtpServerPort = 25;

  /// If true we are using a wildcard dns (e.g. *.squarephone.biz)
  bool domainWildcard = false;

  /// The a list of the names of the selected [ContentProvider]
  /// Items in the list are comma separated with no spaces.
  String? contentProviders;

  /// host path which is mounted into ngix and contains .location
  /// and .upstream files from.
  String? _hostIncludePath;

  /// the DNS authentication provider to be used by certbot
  String? authProvider;

  ///
  bool get isConfigured => d.exists(configPath) && fqdn != null;

  bool get isProduction =>
      certificateType == ConfigYaml.certificateTypeProduction;

  bool get isModePrivate => mode == modePrivate;
  String? get hostIncludePath {
    _hostIncludePath ??= deafultHostIncludePathTo;
    if (_hostIncludePath!.isEmpty) {
      _hostIncludePath = deafultHostIncludePathTo;
    }
    return _hostIncludePath;
  }

  String? get domain {
    if (fqdn == null) {
      return '';
    }

    if (fqdn!.contains('.')) {
      /// return everything but the first part (hostname).
      return fqdn!.split('.').sublist(1).join('.');
    }

    return fqdn;
  }

  String? get hostname {
    if (fqdn == null) {
      return '';
    }

    if (fqdn!.contains('.')) {
      return fqdn!.split('.')[0];
    }

    return fqdn;
  }

  set hostIncludePath(String? hostIncludePath) {
    _hostIncludePath = hostIncludePath;
  }

  Future<void> save() async {
    settings[startMethodKey] = startMethod;
    settings[modeKey] = mode;
    settings[Environment.startPausedKey] = startPaused;
    settings[fqdnKey] = fqdn;
    settings[aliasesKey] = aliases;
    settings[tldKey] = tld;
    settings[imageKey] = '${image?.imageid}';
    settings[certificateTypeKey] = certificateType;
    settings[emailAddressKey] = emailaddress;
    settings[containerIDKey] = containerid;
    settings[authProviderKey] = authProvider;
    settings[contentProviderKey] = contentProviders;
    settings[hostIncludePathKey] = hostIncludePath;

    settings[Environment.smtpServerKey] = smtpServer;
    settings[Environment.smtpServerPortKey] = smtpServerPort;
    settings[Environment.domainWildcardKey] = domainWildcard;

    // ignore: discarded_futures
    await settings.save();
  }

  String get configPath => path.join(d.HOME, configDir, configFile);

  void validate(void Function() showUsage) {
    if (!isConfigured) {
      printerr(
          red("A saved configuration doesn't exist. You must use first run "
              "'nginx-le config."));
      showUsage();
    }

    if (image == null) {
      printerr(red(
          'Your configuration is in an inconsistent state. (image is null). '
          "Run 'nginx-le config'."));
      showUsage();
    }

    if (containerid == null) {
      printerr(red('Your configuration is in an inconsistent state. '
          "(containerid is null). Run 'nginx-le config'."));
      showUsage();
    }

    if (!Containers().existsByContainerId(containerid!)) {
      printerr(red('The ngnix-le container $containerid no longer exists.'));
      printerr(red('  Run nginx-le config to change the container.'));
      exit(1);
    }
    if (!Images().existsByImageId(imageid: image!.imageid!)) {
      printerr(red('The ngnix-le image ${image!.imageid} no longer exists.'));
      printerr(red('  Run nginx-le config to change the image.'));
      exit(1);
    }
  }
}
