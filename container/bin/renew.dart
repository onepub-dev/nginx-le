/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_container/src/commands/internal/renew.dart';

/// In container entry point to run certbot
///
/// The cli renew command calls this command which does the actual
///  certificate renewal
/// within the container.

void main(List<String> args) {
  renew(args);
}
