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
  var authProvider = AuthProviders().getByName(Environment().authProvider!);

  if (authProvider == null) {
    throw 'No value provided for ${Environment().authProviderKey}';
  }

  authProvider.auth_hook();
}
