import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';

/// Isolates inherit the environment from [Platform.environment]
/// this means that any calls to DCli's environment settings are not
/// passed to an isolate.
class IsolateEnvironment {
  String encodeEnviroment() {
    final envMap = <String, String>{}..addEntries(env.entries.toSet());
    return JsonEncoder(_toEncodable).convert(envMap);
  }

  void restoreEnvironment(String environment) {
    env.addAll(Map<String, String>.from(
        const JsonDecoder().convert(environment) as Map<dynamic, dynamic>));
  }

  String _toEncodable(Object? object) => object.toString();
}
