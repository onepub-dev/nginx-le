/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';
import 'package:uuid/uuid.dart';

import '../util/ask_location_path.dart';
import 'content_provider.dart';

class Static extends ContentProvider {
  @override
  String get name => 'static';

  @override
  String get summary => 'Static HTML content from a local directory.';

  @override
  void promptForSettings() {
    /// wwwroot
    print('');
    print(green('Static Web Content'));
    _homePage = ask('Default Page', defaultValue: _homePage);
    _staticRootPath = askForHostPath(
      prompt: 'Path to wwwroot containing $_homePage',
      defaultPath: _staticRootPath,
    );

    askForLocationPath('Host path to store generated `.location` file');
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

  String get _locationFile => 'static.location';
  String get _locationPath =>
      join(ConfigYaml().hostIncludePath!, _locationFile);

  String get _staticRootPath =>
      ConfigYaml().settings['$name-static-wwwroot'] as String? ??
      _defaultStaticRootPath;
  set _staticRootPath(String rootPath) =>
      ConfigYaml().settings['$name-static-wwwroot'] = rootPath;

  String get _homePage =>
      ConfigYaml().settings['$name-home-page'] as String? ?? _defaultHomePage;
  set _homePage(String rootPath) =>
      ConfigYaml().settings['$name-home-page'] = rootPath;

  /// the default for the host wwwroot path
  String get _defaultStaticRootPath => '/opt/nginx/wwwroot';
  String get _defaultHomePage => 'index.html';

  String get _locationContent => '''
location / {
    root   $_staticRootPath;
    index  $_homePage;
}
''';

  @override
  void createLocationFile() {
    _backupLocationContent();
    find('*.location', workingDirectory: ConfigYaml().hostIncludePath!)
        .forEach(delete);

    _locationPath.write(_locationContent);
  }

  @override
  void createUpstreamFile() {
    /// no op as we don't require an upstream file.
    find('*.upstream', workingDirectory: ConfigYaml().hostIncludePath!)
        .forEach(delete);
  }

  @override
  List<Volume> getVolumes() {
    final config = ConfigYaml();
    return [
      Volume(
          hostPath: config.hostIncludePath,
          containerPath: Nginx.containerIncludePath),
      Volume(hostPath: _staticRootPath, containerPath: '/opt/nginx/wwwroot')
    ];
  }

  /// before we write out the location content we check if the users has
  /// modified the content and if so back it up.
  void _backupLocationContent() {
    if (!exists(_locationPath)) {
      return;
    } // nothing to backup
    final onDiskContent = read(_locationPath).toList().join('\n');
    if (onDiskContent != _locationContent) {
      // looks like the user manually changed the contents of the file.
      final backup = '$_locationPath.bak';
      if (exists(backup)) {
        final target = '$backup.${const Uuid().v4()}';
        if (!isWritable(backup)) {
          'mv $backup $target'.start(privileged: true);

          if (isGroupExists('docker')) {
            'chown docker:docker $target'.start(privileged: true);
          }
        } else {
          move(backup, '$backup.${const Uuid().v4()}');
        }
      }

      if (!isWritable(dirname(backup))) {
        'cp $_locationPath $backup'.start(privileged: true);

        if (isGroupExists('docker')) {
          'chown docker:docker $backup'.start(privileged: true);
        }
      } else {
        copy(_locationPath, backup);
      }

      print('Your original location file $_locationPath has been backed '
          'up to $backup');
    }
  }

  bool isGroupExists(String group) {
    final lines = read('/etc/group').toList();
    for (final line in lines) {
      if (line.startsWith('$group:')) {
        return true;
      }
    }
    return false;
  }
}
