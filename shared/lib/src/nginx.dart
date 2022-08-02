/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';

import '../nginx_le_shared.dart';

// ignore: avoid_classes_with_only_static_members
class Nginx {
  /// The include path within the container.
  static const defaultContainerIncludePathTo = '/etc/nginx/include';

  static String get accesslogpath {
    var path = Environment().nginxAccessLogPath;
    return path ??= '/var/log/nginx/access.log';
  }

  /// The default path where nginx looks for the include files
  /// (Locations and Upstream)
  static String get containerIncludePath {
    var path = Environment().nginxLocationIncludePath;
    return path ??= defaultContainerIncludePathTo;
  }

  static String get errorlogpath {
    var path = Environment().nginxErrorLogPath;
    return path ??= '/var/log/nginx/error.log';
  }

  static void reload() {
    if (exists('/var/run/nginx.pid')) {
      /// force nginx to reload its config.
      'nginx -s reload'.run;
    } else {
      verbose(() => 'Nginx reload ignored as nginx is not running');
    }
  }
}
