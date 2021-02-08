#! /usr/bin/env dcli

import 'package:nginx_le_container/src/commands/internal/deploy_hook.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'mock_cerbot_paths.dart';

/// Used by unit tests. This code runs the same logic as deploy_hook
/// but mocks the paths to /tmp.
void main() {
  var paths = MockCertbotPaths();
  paths.wireEnvironment();
  paths.wirePaths();

  paths.setMock();

  print('rootpath: ${CertbotPaths().letsEncryptRootPath}');
  print('logpath: ${CertbotPaths().letsEncryptLogPath}');

  deploy_hook();
}
