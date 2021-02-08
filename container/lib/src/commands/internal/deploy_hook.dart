import 'package:nginx_le_shared/nginx_le_shared.dart';

void deploy_hook() {
  print('deploy_hook: hostname: ${Environment().hostname}');
  print('deploy_hook: domain: ${Environment().domain}');
  print('deploy_hook: domainWildcard: ${Environment().domainWildcard}');
  print('deploy_hook: autoAcquire: ${Environment().autoAcquire}');
  print(
      'deploy_hook: renewedLinagePath: ${Environment().certbotDeployHookRenewedLineagePath}');

  Certbot().deployCertificatesDirect(
      Environment().certbotDeployHookRenewedLineagePath);
}
