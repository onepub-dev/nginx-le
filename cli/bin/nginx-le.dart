#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

// ignore_for_file: file_names

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dcli/dcli.dart';
import 'package:nginx_le/nginx_le.dart';
import 'package:nginx_le/src/commands/external/certificates_command.dart';
import 'package:nginx_le/src/commands/external/config_command.dart';
import 'package:nginx_le/src/commands/external/doctor_command.dart';
import 'package:nginx_le/src/commands/external/logs_command.dart';
import 'package:nginx_le/src/commands/external/renew_command.dart';
import 'package:nginx_le/src/commands/external/restart_command.dart';
import 'package:nginx_le/src/commands/external/revoke_command.dart';
import 'package:nginx_le/src/commands/external/stop_command.dart';
import 'package:nginx_le/src/version/version.g.dart';

enum Mode { public, private }

/// Starts the ngix docker instance
void main(List<String> args) {
  final runner = CommandRunner<void>('nginx-le',
      'Cli tools to manage your nginx-le server. Version: $packageVersion')
    ..addCommand(BuildCommand())
    ..addCommand(ConfigCommand())
    ..addCommand(StartCommand())
    ..addCommand(RestartCommand())
    ..addCommand(AcquireCommand())
    ..addCommand(RevokeCommand())
    ..addCommand(RenewCommand())
    ..addCommand(CliCommand())
    ..addCommand(StopCommand())
    ..addCommand(LogsCommand())
    ..addCommand(DoctorCommand())
    ..addCommand(CertificatesCommand());

  if (args.isEmpty) {
    printerr('No command was passed.');
    runner.printUsage();
    exit(1);
  }

  runner.run(args).catchError((dynamic e) {
    printerr(e.toString());
    print(runner.usage);
    exit(1);
  }, test: (e) => e is UsageException);
}
