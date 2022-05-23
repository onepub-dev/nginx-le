import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../content_providers/content_providers.dart';

/// Starts nginx and the certbot scheduler.
class DoctorCommand extends Command<void> {
  DoctorCommand();

  @override
  String get description =>
      'Displays current config and diagnostic information';

  @override
  String get name => 'doctor';

  @override
  void run() {
    print('');
    _colprint(['OS', (Platform.operatingSystem)]);
    print(Format().row(['OS Version', (Platform.operatingSystemVersion)],
        widths: [17, -1]));
    _colprint(['Path separator', (Platform.pathSeparator)]);
    print('');
    _colprint(['dart version', (DartSdk().version)]);
    print('');

    print('');

    print('PATH');
    for (final path in PATH) {
      _colprint(['', privatePath(path)]);
    }

    print('');
    print('Dart location(s)');
    which('dart').paths.forEach((line) => _colprint(['', line]));

    print('');
    print('Permissions');
    _showPermissions('HOME', HOME);
    _showPermissions('.dcli', Settings().pathToDCli);

    final config = ConfigYaml();

    print('');
    print(green('Nginx-LE configuration file'));
    _colprint(['ConfigPath', config.configPath]);
    _colprint(['Mode', config.mode]);
    _colprint(['FQDN', config.fqdn]);
    _colprint([(Environment.tldKey), config.tld]);
    _colprint(['Docker ImageID', config.image?.imageid]);
    _colprint(['Cert Type', config.certificateType]);
    _colprint(['Docker container', config.containerid]);
    _colprint(['Auth Provider', config.authProvider]);

    final authProvider = AuthProviders().getByName(config.authProvider!)!;
    final envs = authProvider.environment;
    for (final env in envs) {
      _colprint([env.name, env.value]);
    }

    final provider = ContentProviders().getByName(config.contentProvider)!;
    print('');
    _colprint(['Content Provider', config.contentProvider]);
    for (final volume in provider.getVolumes()) {
      _colprint([
        'Volume',
        'host: ${volume.hostPath}',
        'container: ${volume.containerPath}'
      ]);
    }

    print('');

    if (config.image == null) {
      printerr(
          red("The image has not been configured.  Run 'nginx-le config'"));
    } else {
      final image = Images().findByImageId(config.image!.imageid ?? '');

      if (image == null) {
        printerr(red('The Image ${config.image!.imageid} does not exist'));
      }
      {
        _colprint(['Image Name', config.image!.fullname]);
      }
    }

    if (config.containerid == null) {
      printerr(
          red("The Container has not been configured. Run 'nginx-le config'"));
    } else {
      final container = Containers().findByContainerId(config.containerid!);

      if (container == null) {
        printerr(red('The Container ${config.containerid} does not exist'));
      } else {
        _colprint([
          'Container Name',
          container.name,
          'Running',
          container.isRunning.toString()
        ]);
      }
    }
  }

  void _colprint(List<String?> cols) {
    if (cols[1] == null) {
      cols[1] = '<null>';
    }
    //cols[0] = green(cols[0]);
    print(Format().row(cols, widths: [17, 55], delimiter: ' '));
  }

  void _showPermissions(String label, String path) {
    if (exists(path)) {
      final fstat = stat(path);

      final owner = _Owner(path);

      // ignore: parameter_assignments
      label = label.padRight(20);

      final username = env['USERNAME'];
      if (username != null) {
        print(Format().row([
          label,
          (fstat.modeString()),
          '<user>:${owner.group == owner.user ? '<user>' : owner.group}',
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
      _colprint([label, '${privatePath(path)} does not exist']);
    }
  }

  void showUsage(ArgParser parser) {
    print(parser.usage);
    exit(-1);
  }
}

class _Owner {
  _Owner(String path) {
    if (Settings().isWindows) {
      user = 'Unknown';
      group = 'Unknown';
    } else {
      final lsLine = 'ls -alFd $path'.firstLine;

      if (lsLine == null) {
        throw DCliException('No file/directory matched ${absolute(path)}');
      }

      final parts = lsLine.split(' ');
      user = parts[2];
      group = parts[3];
    }
  }
  String? user;
  String? group;

  @override
  String toString() => '$user:$group';
}
