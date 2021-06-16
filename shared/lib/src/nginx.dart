import 'package:dcli/dcli.dart';

import '../nginx_le_shared.dart';

class Nginx {
  /// The include path within the container.
  static const DEFAULT_CONTAINER_INCLUDE_PATH = '/etc/nginx/include';

  static String get accesslogpath {
    var path = Environment().nginxAccessLogPath;
    path ??= '/var/log/nginx/access.log';
    return path;
  }

  /// The default path where nginx looks for the include files (Locations and Upstream)
  static String get containerIncludePath {
    var path = Environment().nginxLocationIncludePath;
    path ??= DEFAULT_CONTAINER_INCLUDE_PATH;
    return path;
  }

  static String get errorlogpath {
    var path = Environment().nginxErrorLogPath;
    path ??= '/var/log/nginx/error.log';
    return path;
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
