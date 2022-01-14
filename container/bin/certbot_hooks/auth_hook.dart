#! /usr/bin/env dcli

import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Runs within the container.
///
/// This app is called by Certbot to provide the DNS validation.
///
/// The technique used is dependant on the selected authProvider
/// which is set via the environment variable: [Environment().authProvider]
///
void main() {
  final providerName = Environment().authProvider;
  if (providerName == null) {
    throw Exception('No value provided for environment variable AUTH_PROVIDER');
  }
  final authProvider = AuthProviders().getByName(providerName);

  if (authProvider == null) {
    throw Exception('No value provided for ${Environment().authProviderKey}');
  }

  authProvider.authHook();
}
