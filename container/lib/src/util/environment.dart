import 'dart:convert';

import 'package:dcli/dcli.dart';

/// Isolates inherit the environment from [Platform.environment]
/// this means that any calls to DCli's environment settings are not
/// passed to an isolate.
class IsolateEnvironment {
  String encodeEnviroment() {
    var envMap = <String, String>{};
    envMap.addEntries(env.entries.toSet());
    return JsonEncoder(_toEncodable).convert(envMap);
  }

  void restoreEnvironment(String environment) {
    env.addAll(Map<String, String>.from(JsonDecoder().convert(environment) as Map<dynamic, dynamic>));
  }

  String _toEncodable(Object object) {
    return object.toString();
  }
}
