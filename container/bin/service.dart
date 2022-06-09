/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_container/nginx_le_container.dart';
import 'package:nginx_le_container/src/commands/internal/service.dart';

/// The container entry point to run nginx.
/// This starts the primary nginx service thread.
void main() {
  startService();
}
