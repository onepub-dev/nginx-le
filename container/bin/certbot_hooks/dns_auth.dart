#! /usr/bin/env dcli

import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Runs within the container.
///
/// This app is called by Certbot to provide the DNS validation.
///
/// This app creates a DNS TXT record _acme-challenge containing the validation
/// key.
/// The app then loops until the TXT record is propergated to local DNS servers.
///
/// Once the TXT record is available we return an let
///
void main() {
  var authProvider = AuthProviders().getByName(Environment().certbotAuthProvider);

  authProvider.acquire();
}
