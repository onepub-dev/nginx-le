import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_provider.dart';
import 'package:nginx_le_shared/src/util/environment.dart';
import 'package:test/test.dart';

void main() {
  test('auth provider ...', () async {
    Environment().certbotDNSAuthHookPath =
        join(HOME, 'git', 'nginx-le', 'cli', 'bin', 'nginx-le.dart ');
    var provider = NameCheapAuthProvider();
    var apiKey = ask('Namecheap API Key');
    var apiUsername = ask('Namecheap Username');
    provider.envToken = apiKey;
    provider.envUsername = apiUsername;
    provider.acquire();
  });
}
