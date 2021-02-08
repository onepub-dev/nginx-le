#! /usr/bin/env dcli

import 'package:nginx_le_container/src/commands/internal/deploy_hook.dart';

/// Runs within the container.
///
/// This app is used by the renewal process for all auth providers.
///
/// Its job is to deploy the renewed certificates.
///
/// During renewal Cerbot only calls the deploy hook if the certificates were
/// renewed.
///
/// As there is no other simple way to detect a successful renewal
/// we use this deploy hook.
///
void main() {
  deploy_hook();
}
