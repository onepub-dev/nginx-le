import 'package:dshell/dshell.dart';

class Nginx {
  static const NGINX_ACCESS_LOG_ENV = 'NGINX_ACCESS_LOG_ENV';
  static const NGINX_ERROR_LOG_ENV = 'NGINX_ERROR_LOG_ENV';
  static const NGINX_LOCATION_INCLUDE_PATH = 'NGINX_LOCATION_INCLUDE_PATH';

  static const DEFAULT_INCLUDE_PATH = '/opt/nginx/include';

  static String get accesslogpath {
    var path = env(NGINX_ACCESS_LOG_ENV);
    path ??= '/var/log/nginx/access.log';
    return path;
  }

  /// The default path where nginx looks for the include files (Locations and Upstream)
  static String get locationIncludePath {
    var path = env(NGINX_LOCATION_INCLUDE_PATH);
    path ??= DEFAULT_INCLUDE_PATH;
    return path;
  }

  static String get errorlogpath {
    var path = env(NGINX_ERROR_LOG_ENV);
    path ??= '/var/log/nginx/error.log';
    return path;
  }
}
