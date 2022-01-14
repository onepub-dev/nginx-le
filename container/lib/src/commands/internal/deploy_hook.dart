import 'package:nginx_le_shared/nginx_le_shared.dart';

/// The [reload] is used for testing when we are not running nginx
/// so don't want to do
/// an nginx reload.
void deployHook({required bool reload}) {
  print('deploy_hook: hostname: ${Environment().hostname}');
  print('deploy_hook: domain: ${Environment().domain}');
  print('deploy_hook: domainWildcard: ${Environment().domainWildcard}');
  print('deploy_hook: autoAcquire: ${Environment().autoAcquire}');
  print('deploy_hook: renewedLinagePath: '
      '${Environment().certbotDeployHookRenewedLineagePath}');

  Certbot().deployCertificatesDirect(
      Environment().certbotDeployHookRenewedLineagePath!,
      reload: reload);
}
