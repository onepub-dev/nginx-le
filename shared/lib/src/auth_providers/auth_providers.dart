import 'package:nginx_le_shared/src/auth_providers/dns_auth_providers/dns_auth_providers.dart';
import 'package:nginx_le_shared/src/auth_providers/http_auth_providers/http_auth.dart';

import 'auth_provider.dart';

/// Each [AuthProviders] must be registered with this class.
class AuthProviders {
  static final AuthProviders _self = AuthProviders._init();
  factory AuthProviders() => _self;

  AuthProviders._init();

  /// Finds and returns a [AuthProvider] via its name.
  AuthProvider getByName(String name) {
    if (name == HTTPAuthProvider().name) return HTTPAuthProvider();

    for (var provider in DnsAuthProviders().providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }
}
