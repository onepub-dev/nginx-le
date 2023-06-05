#! /usr/bin/env dcli
/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:nginx_le_container/src/commands/internal/deploy_hook.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Used by unit tests. This code runs the same logic as deploy_hook
/// but mocks the paths to /tmp.
void main() {
  withTempDir((dir) {
    // MockCertbotPaths(
    //     hostname: 'auditor',
    //     domain: 'squarephone.biz',
    //     wildcard: false,
    //     tld: 'com.au',
    //     settingsFilename: 'cloudflare.yaml',
    //     rootDir: dir,
    //     possibleCerts: [
    //       PossibleCert('auditor', 'squarephone.biz', wildcard: false)
    //     ]).wire();

    /// /tmp/etc/letsencrypt/config/live/auditor.squarephone.biz
    // Environment().certbotDeployHookRenewedLineagePath =
    //     '/tmp/etc/letsencrypt/config/live/auditor.squarephone.biz';

//  CertbotPaths().latestCertificatePath(hostname, domain, wildcard: wildcard);

    print('rootpath: ${CertbotPaths().letsEncryptRootPath}');
    print('logpath: ${CertbotPaths().letsEncryptLogPath}');
    print('certbotDeployHookRenewedLineagePath: '
        '${Environment().certbotDeployHookRenewedLineagePath}');

    deployHook(reload: false);
  });
}
