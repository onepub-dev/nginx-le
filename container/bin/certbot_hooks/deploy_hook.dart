#! /usr/bin/env dcli

import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Runs within the container.
///
/// This app is used by the renewal process for all auth providers.
///
/// Its job is to deploy the renewed certificates.
///
/// During renewal Cerbot only calls the deploy hook if the certificates were
/// renewed.
///
/// As there is no other simple way to detect a successful renewal
/// we use this deploy hook.
///
void main() {
  print('deploy_hook: hostname: ${Environment().hostname}');
  print('deploy_hook: domain: ${Environment().domain}');
  print('deploy_hook: domainWildcard: ${Environment().domainWildcard}');
  print('deploy_hook: autoAcquire: ${Environment().autoAcquire}');
  print(
      'deploy_hook: renewedLinagePath: ${Environment().certbotDeployHookRenewedLineagePath}');
  Certbot().deployCertificatesDirect(
      Environment().certbotDeployHookRenewedLineagePath);
}
