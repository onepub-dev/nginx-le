import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/cloudflare/cloudflare_provider.dart';
import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/namecheap/namecheap_provider.dart';

import '../auth_provider.dart';

/// Each [DnsAuthProviders] must be registered with this class.
class DnsAuthProviders {
  static final DnsAuthProviders _self = DnsAuthProviders._init();
  factory DnsAuthProviders() => _self;

  var providers = <AuthProvider>[NameCheapAuthProvider(), CloudFlareProvider()];
  DnsAuthProviders._init() {
    var names = <String, AuthProvider>{};

    for (var provider in providers) {
      if (names.containsKey(provider.name)) {
        throw ArgumentError(
            'The DnsAuthProvider name ${provider.name} is already used.');
      }
    }

    // sort providers alphabetically.
    providers.sort((lhs, rhs) => lhs.name.compareTo(rhs.name));
  }

  /// Finds and returns a [ContentProvider] via its name.
  AuthProvider getByName(String name) {
    for (var provider in providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }
}
