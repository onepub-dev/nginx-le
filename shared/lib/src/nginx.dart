import '../nginx_le_shared.dart';

class Nginx {
  static const NGINX_ACCESS_LOG_PATH = 'NGINX_ACCESS_LOG_PATH';
  static const NGINX_ERROR_LOG_PATH = 'NGINX_ERROR_LOG_PATH';
  static const NGINX_LOCATION_INCLUDE_PATH = 'NGINX_LOCATION_INCLUDE_PATH';

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
}
