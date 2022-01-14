import '../../nginx_le_shared.dart';
import 'dns_auth_providers/cloudflare/cloudflare_provider.dart';
import 'dns_auth_providers/namecheap/namecheap_auth_provider.dart';

/// Each [AuthProviders] must be registered with this class.
class AuthProviders {
  factory AuthProviders() => _self;

  AuthProviders._init() {
    final names = <String, AuthProvider>{};

    for (final provider in providers) {
      if (names.containsKey(provider.name)) {
        throw ArgumentError(
            'The AuthProvider name ${provider.name} is already used.');
      }
    }

    // sort providers alphabetically.
    providers.sort((lhs, rhs) => lhs.name.compareTo(rhs.name));
  }

  static final AuthProviders _self = AuthProviders._init();

  /// Add new auth providers to this list.
  List<AuthProvider> providers = <AuthProvider>[
    HTTPAuthProvider(),
    NameCheapAuthProvider(),
    CloudFlareProvider()
  ];

  /// Finds and returns a [AuthProvider] via its name.
  AuthProvider? getByName(String name) {
    for (final provider in providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }

  /// Returns a list of provides that are valid for the given configuration.
  List<AuthProvider> getValidProviders(ConfigYaml config) {
    final mode = config.mode;
    final wildcard = config.domainWildcard;

    final valid = <AuthProvider>[];

    for (final provider in providers) {
      if ((!wildcard || (wildcard && provider.supportsWildCards)) &&
          (mode == ConfigYaml.modePublic ||
              (mode == ConfigYaml.modePrivate &&
                  provider.supportsPrivateMode))) {
        valid.add(provider);
      }
    }
    return valid;
  }
}
