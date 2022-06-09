/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'conduit.dart';
import 'content_provider.dart';
import 'custom.dart';
import 'generic_proxy.dart';
import 'static.dart';
import 'tomcat.dart';

/// Each [ContentProvider] must be registered with this class.
class ContentProviders {
  factory ContentProviders() => _self;

  ContentProviders._init() {
    final names = <String, ContentProvider>{};

    for (final provider in providers) {
      if (names.containsKey(provider.name)) {
        throw ArgumentError(
            'The ContentProvider name ${provider.name} is already used.');
      }
    }

    // sort providers alphabetically.
    providers.sort((lhs, rhs) => lhs.name.compareTo(rhs.name));
  }

  static final ContentProviders _self = ContentProviders._init();

  List<ContentProvider> providers = <ContentProvider>[
    Custom(),
    GenericProxy(),
    Static(),
    Tomcat(),
    Conduit(),
  ];

  /// Finds and returns a [ContentProvider] via its name.
  ContentProvider? getByName(String? name) {
    for (final provider in providers) {
      if (provider.name == name) {
        return provider;
      }
    }
    return null;
  }
}
