#! /usr/bin/env dshell

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dshell/dshell.dart';
import 'package:nginx_le/nginx_le.dart';
import 'package:nginx_le/src/commands/external/certificates_command.dart';
import 'package:nginx_le/src/commands/external/config_command.dart';
import 'package:nginx_le/src/commands/external/doctor_command.dart';
import 'package:nginx_le/src/commands/external/logs_command.dart';
import 'package:nginx_le/src/commands/external/restart_command.dart';
import 'package:nginx_le/src/commands/external/revoke_command.dart';
import 'package:nginx_le/src/commands/external/stop_command.dart';
import 'package:nginx_le/src/version/version.g.dart';

enum Mode { public, private }

/// Starts the ngix docker instance
void main(List<String> args) {
  var runner = CommandRunner<void>('nginx-le',
      'Cli tools to manage your nginx-le server. Version: $packageVersion');

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
