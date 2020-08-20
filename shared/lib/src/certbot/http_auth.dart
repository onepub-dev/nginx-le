import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_shared/src/util/environment.dart';

import 'certbot.dart';

void http_auth_acquire({
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

  /// These are set via in the Dockerfile
  var auth_hook = Environment().certbotHTTPAuthHookPath;
  var cleanup_hook = Environment().certbotHTTPCleanupHookPath;

  ArgumentError.checkNotNull(auth_hook, 'Environment variable: CERTBOT_HTTP_AUTH_HOOK_PATH missing');
  ArgumentError.checkNotNull(cleanup_hook, 'Environment variable: CERTBOT_HTTP_CLEANUP_HOOK_PATH missing');

  var certbot = 'certbot certonly '
      ' --manual '
      ' --preferred-challenges=http '
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
      runInShell: true, nothrow: true, progress: Progress((line) => print(line), stderr: (line) => printerr(line)));
}

String _createDir(String dir) {
  if (!exists(dir)) {
    createDir(dir, recursive: true);
  }
  return dir;
}
