/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:nginx_le_container/src/commands/internal/logs.dart';

/// In container entry point to run nginx
/// The cli logs command calls this command which does the
/// actual tailing of logs
/// within the container.
void main(List<String> args) async {
  await logs(args);
}
