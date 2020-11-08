import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_auth_provider.dart';
import 'package:nginx_le_shared/src/util/environment.dart';
import 'package:test/test.dart';

void main() {
  test('auth provider ...', () async {
    Environment().certbotAuthHookPath =
        join(HOME, 'git', 'nginx-le', 'container', 'bin', 'certbot_hooks', 'auth_hook_path');
    var provider = NameCheapAuthProvider();
    var apiKey = ask('Namecheap API Key');
    var apiUsername = ask('Namecheap Username');
    provider.envToken = apiKey;
    provider.envUsername = apiUsername;
    provider.acquire();
  });
}
