import 'package:nginx_le_shared/src/auth_providers/http_auth_providers/http_auth_provider.dart';

import '../../nginx_le_shared.dart';
import 'auth_provider.dart';
import 'dns_auth_providers/cloudflare/cloudflare_provider.dart';
import 'dns_auth_providers/namecheap/namecheap_auth_provider.dart';

/// Each [AuthProviders] must be registered with this class.
class AuthProviders {
  static final AuthProviders _self = AuthProviders._init();

  /// Add new auth providers to this list.
  var providers = <AuthProvider>[
    HTTPAuthProvider(),
    NameCheapAuthProvider(),
    CloudFlareProvider()
  ];

  factory AuthProviders() => _self;
  AuthProviders._init() {
    var names = <String, AuthProvider>{};

    for (var provider in providers) {
      if (names.containsKey(provider.name)) {
        throw ArgumentError(
            'The AuthProvider name ${provider.name} is already used.');
      }
    }

    // sort providers alphabetically.
    providers.sort((lhs, rhs) => lhs.name.compareTo(rhs.name));
  }

  /// Finds and returns a [ContentProvider] via its name.
  AuthProvider? getByName(String name) {
    for (var provider in providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }

  /// Returns a list of provides that are valid for the given configuration.
  List<AuthProvider> getValidProviders(ConfigYaml config) {
    var mode = config.mode;
    var wildcard = config.domainWildcard;

    var valid = <AuthProvider>[];

    for (var provider in providers) {
      if ((!wildcard || (wildcard && provider.supportsWildCards)) &&
          (mode == ConfigYaml.MODE_PUBLIC ||
              (mode == ConfigYaml.MODE_PRIVATE &&
                  provider.supportsPrivateMode))) {
        valid.add(provider);
      }
    }
    return valid;
  }
}
