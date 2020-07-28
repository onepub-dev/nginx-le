#! /usr/bin/env dshell
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_cli/nginx_le_cli.dart';
import 'package:nginx_le_cli/src/commands/external/certificates_command.dart';
import 'package:nginx_le_cli/src/commands/external/config_command.dart';
import 'package:nginx_le_cli/src/commands/external/doctor_command.dart';
import 'package:nginx_le_cli/src/commands/external/logs_command.dart';
import 'package:nginx_le_cli/src/commands/external/restart_command.dart';
import 'package:nginx_le_cli/src/commands/external/revoke_command.dart';
import 'package:nginx_le_cli/src/commands/external/stop_command.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

enum Mode { public, private }

/// Starts the ngix docker instance
void main(List<String> args) {
  var runner = CommandRunner<void>(
      'nginx-le', 'Cli tools to manage your nginx-le server');

  runner.addCommand(BuildCommand());
  runner.addCommand(ConfigCommand());
  runner.addCommand(StartCommand());
  runner.addCommand(RestartCommand());
  runner.addCommand(AcquireCommand());
  runner.addCommand(RevokeCommand());
  runner.addCommand(CliCommand());
  runner.addCommand(StopCommand());
  runner.addCommand(LogsCommand());
  runner.addCommand(DoctorCommand());
  runner.addCommand(CertificatesCommand());

  if (args.isEmpty) {
    printerr('No command was passed.');
    runner.printUsage();
    exit(1);
  }

  runner.run(args).catchError((Object e) {
    printerr(e.toString());
    print(runner.usage);
    exit(1);
  }, test: (e) => e is UsageException);
}

void usage(ArgParser parser) {
  print('');
  print('nginx-le - Runs nginx with builtin certificate renewal');
  print('');
  print('Available Commands:');
  print('  build - builds an nginx-le image ');
  print('  start - starts an nginx-le container ');
  print(
      '  acquire - obtains or renews a certficate when running in private mode.');
  print('  cli - attaches to the containers cli.');
  print(parser.usage);
  exit(1);
}

void run(
    {@required String cmd,
    @required String hostname,
    @required String domain,
    @required String tld,
    @required String emailaddress,
    @required String mode,
    @required bool debug}) {
  /// The volume will only be created if it doesn't already exist.
  print('Creating certificates volume');
  'docker volume create certificates'
      .forEach(devNull, stderr: (line) => print(red(line)));

  print('Creating lastpass volume');
  'docker volume create lastpass'
      .forEach(devNull, stderr: (line) => print(red(line)));

  setEnv('HOSTNAME', hostname);
  setEnv('DOMAIN', hostname);
  setEnv('TLD', tld);
  setEnv('EMAIL_ADDRESS', emailaddress);
  setEnv('MODE', mode);
  setEnv('DEBUG', '$debug');
  setEnv('LETS_ENCRYPT_ROOT_PATH', Certbot.letsEncryptRootPath);

  'docker-compose up '.run;
}
