#! /usr/bin/env dshell

import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_shared/src/namecheap/env.dart';

import 'certbot.dart';

/// Obtains a lets-encrypt certificate for use in a development environment where the
/// ngix server doesn't have a public ip address.
///
/// In this case we use the DNS Validation api which requires us to publish a DNS record
/// to our DNS servers.
///
/// This requires access to LastPass to obtain the DNS API keys as such this command needs to be
/// run in an intractive terminal as you will need to login to LastPass.
///
/// To avoid having to run 2fa with LastPass every time we expect that a Docker persistent volume
/// will be mounted to /root/.lastpass.
///
//const tomcatPath = '$HOME/apps/tomcat vi ./apache-tomcat-9.0.16/conf/server.xml';

/// The [hostname] and [domain] of the webserver we are obtaining certificates for.
/// The [emailaddress] that renewal reminders will be sent to.
/// If [mode] is public than a lets-encrypt certificate will be obtained
///  otherwise a staging certificate will be obtained.
/// The default [mode] value is private.
void dns_auth_acquire({
  @required String hostname,
  @required String domain,
  @required String tld,
  @required String emailaddress,
  bool staging = false,
  bool debug = true,
}) {
  var workDir = _createDir(Certbot.letsEncryptWorkPath);
  var logDir = _createDir(Certbot.letsEncryptLogPath);
  var configDir = _createDir(Certbot.letsEncryptConfigPath);

  /// Pass environment vars down to the auth hook.
  setEnv('LOG_FILE', join(logDir, 'letsencrypt.log'));
  setEnv('TLD', tld);

  /// These are set via in the Dockerfile
  var auth_hook = env('CERTBOT_DNS_AUTH_HOOK_PATH');
  var cleanup_hook = env('CERTBOT_DNS_CLEANUP_HOOK_PATH');

  ArgumentError.checkNotNull(
      auth_hook, 'Environment variable: CERTBOT_DNS_AUTH_HOOK_PATH missing');
  ArgumentError.checkNotNull(cleanup_hook,
      'Environment variable: CERTBOT_DNS_CLEANUP_HOOK_PATH missing');

  ArgumentError.checkNotNull(env(NAMECHEAP_API_KEY),
      'Environment variable: NAMECHEAP_API_KEY missing');

  ArgumentError.checkNotNull(env(NAMECHEAP_API_USER),
      'Environment variable: NAMECHEAP_API_USER missing');

  var certbot = 'certbot certonly '
      ' --manual '
      ' --preferred-challenges=dns '
      ' -m $emailaddress  '
      ' -d $hostname.$domain '
      ' --agree-tos '
      ' --manual-public-ip-logging-ok '
      ' --non-interactive '
      ' --manual-auth-hook="$auth_hook" '
      ' --manual-cleanup-hook="$cleanup_hook" '
      ' --work-dir=$workDir '
      ' --config-dir=$configDir '
      ' --logs-dir=$logDir ';

  if (staging) certbot += ' --staging ';

  certbot.start(
      runInShell: true,
      nothrow: true,
      progress:
          Progress((line) => print(line), stderr: (line) => printerr(line)));
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
