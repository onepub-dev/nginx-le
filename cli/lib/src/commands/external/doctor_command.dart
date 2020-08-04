import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Starts nginx and the certbot scheduler.
class DoctorCommand extends Command<void> {
  @override
  String get description =>
      'Displays current config and diagnostic information';

  @override
  String get name => 'doctor';

  DoctorCommand();

  @override
  void run() {
    print('');
    _colprint(['OS', '${Platform.operatingSystem}']);
    print(Format.row(['OS Version', '${Platform.operatingSystemVersion}'],
        widths: [17, -1]));
    _colprint(['Path separator', '${Platform.pathSeparator}']);
    print('');
    _colprint(['dart version', '${DartSdk().version}']);
    print('');

    print('');

    print('PATH');
    for (var path in PATH) {
      _colprint(['', privatePath(path)]);
    }

    print('');
    print('Dart location(s)');
    which('dart').forEach((line) => _colprint(['', line]));

    print('');
    print('Permissions');
    _showPermissions('HOME', HOME);
    _showPermissions('.dshell', Settings().dshellPath);
    _showPermissions('cache', Settings().dshellCachePath);

    var config = ConfigYaml();

    print('');
    print(green('Nginx-LE configuration file'));
    _colprint(['ConfigPath', config.configPath]);
    _colprint(['Mode', config.mode]);
    _colprint(['Hostname', config.hostname]);
    _colprint(['Domain', config.domain]);
    _colprint(['TLD', config.tld]);
    _colprint(['Docker ImageID', config.image?.imageid]);
    _colprint(['Cert Type', config.certificateType]);
    _colprint(['Docker container', config.containerid]);
    _colprint(['DNS Provider', config.dnsProvider]);
    _colprint(['Namecheap api key', config.namecheap_apikey]);
    _colprint(['Namecheap api username', config.namecheap_apiusername]);

    print('');
    _colprint(['Content Source', config.contentSourceType]);
    if (config.contentSourceType == ConfigYaml.CONTENT_SOURCE_PATH) {
      _colprint(['WWW Root', config.wwwRoot]);
    } else {
      _colprint(['Host Include Path', config.hostIncludePath]);
    }

    print('');

    if (config.image == null) {
      printerr(
          red("The image has not been configured.  Run 'nginx-le config'"));
    } else {
      var image = Images().findByImageId(config.image.imageid);

      if (image == null) {
        printerr(red('The Image ${image.imageid} does not exist'));
      }
      {
        _colprint(['Image Name', image.fullname]);
      }
    }

    if (config.containerid == null) {
      printerr(
          red("The Container has not been configured. Run 'nginx-le config'"));
    } else {
      var container = Containers().findByContainerId(config.containerid);

      if (container == null) {
        printerr(red('The Container ${config.containerid} does not exist'));
      }
      {
        _colprint([
          'Container Name',
          container.names,
          'Running',
          container.isRunning.toString()
        ]);
      }
    }
  }

  void _colprint(List<String> cols) {
    if (cols[1] == null) {
      cols[1] = '<null>';
    }
    //cols[0] = green(cols[0]);
    print(Format.row(cols, widths: [17, 55], delimiter: ' '));
  }

  void _showPermissions(String label, String path) {
    if (exists(path)) {
      var fstat = stat(path);

      var owner = _Owner(path);

      label = label.padRight(20);

      var username = env('USERNAME');
      if (username != null) {
        print(Format.row([
          '$label',
          '${fstat.modeString()}',
          '<user>:${(owner.group == owner.user ? '<user>' : owner.group)}',
          '${privatePath(path)} '
        ], widths: [
          17,
          9,
          16,
          -1
        ], alignments: [
          TableAlignment.left,
          TableAlignment.left,
          TableAlignment.middle,
          TableAlignment.left
        ]));
      }
    } else {
      _colprint(['$label', '${privatePath(path)} does not exist']);
    }
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}

class _Owner {
  String user;
  String group;

  _Owner(String path) {
    if (Platform.isWindows) {
      user = 'Unknown';
      group = 'Unknown';
    } else {
      var lsLine = 'ls -alFd $path'.firstLine;

      if (lsLine == null) {
        throw DShellException('No file/directory matched ${absolute(path)}');
      }

      var parts = lsLine.split(' ');
      user = parts[2];
      group = parts[3];
    }
  }

  @override
  String toString() {
    return '$user:$group';
  }
}
