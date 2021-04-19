import 'conduit.dart';
import 'content_provider.dart';
import 'custom.dart';
import 'static.dart';
import 'generic_proxy.dart';
import 'tomcat.dart';

/// Each [ContentProvider] must be registered with this class.
class ContentProviders {
  static final ContentProviders _self = ContentProviders._init();
  factory ContentProviders() => _self;

  var providers = <ContentProvider>[
    Custom(),
    GenericProxy(),
    Static(),
    Tomcat(),
    Conduit(),
  ];
  ContentProviders._init() {
    var names = <String, ContentProvider>{};

    for (var provider in providers) {
      if (names.containsKey(provider.name)) {
        throw ArgumentError(
            'The ContentProvider name ${provider.name} is already used.');
      }
    }

    // sort providers alphabetically.
    providers.sort((lhs, rhs) => lhs.name.compareTo(rhs.name));
  }

  /// Finds and returns a [ContentProvider] via its name.
  ContentProvider? getByName(String? name) {
    for (var provider in providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }
}
