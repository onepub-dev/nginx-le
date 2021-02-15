#! /usr/bin/env dcli

import 'package:nginx_le_container/src/commands/internal/deploy_hook.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'mock_cerbot_paths.dart';

/// Used by unit tests. This code runs the same logic as deploy_hook
/// but mocks the paths to /tmp.
void main() {
  var paths = MockCertbotPaths(
      hostname: 'auditor',
      domain: 'noojee.com.au',
      wildcard: false,
      tld: 'com.au',
      settingsFilename: 'cloudflare.yaml',
      possibleCerts: [
        PossibleCert('auditor', 'noojee.com.au', wildcard: false)
      ]);
  paths.wire();

  /// /tmp/etc/letsencrypt/config/live/auditor.noojee.com.au
  // Environment().certbotDeployHookRenewedLineagePath =
  //     '/tmp/etc/letsencrypt/config/live/auditor.noojee.com.au';

//  CertbotPaths().latestCertificatePath(hostname, domain, wildcard: wildcard);

  print('rootpath: ${CertbotPaths().letsEncryptRootPath}');
  print('logpath: ${CertbotPaths().letsEncryptLogPath}');
  print(
      'certbotDeployHookRenewedLineagePath: ${Environment().certbotDeployHookRenewedLineagePath}');

  deploy_hook(reload: false);
}
