import 'package:dshell/dshell.dart';
import 'package:nginx_le_cli/src/config/ConfigYaml.dart';

abstract class Location {
  static const DEFAULT_INCLUDE_PATH = '/etc/nginx/includes';

  String build();

  /// The name of the file we store the wwwroot location config.
  String get fileName;
}

/// Creates a template for a locations file.
class WwwRoot implements Location {
  /// The path to the wwwroot.
  String rootpath;

  WwwRoot(this.rootpath);

  @override
  String build() {
    return '''location / {
    root   ${truepath(rootpath)};
    index  index.html index.htm;
}
        ''';
  }

  @override
  String get fileName => 'wwwroot.location';

  String get preferredPath => join('/', 'usr', 'share', 'nginx', 'html');

  /// The path where we store the wwwroots location config
  /// This will normally be /etc/nginx/locations/wwwroot.location
  String get locationConfigPath =>
      join(ConfigYaml().includePath, 'locations', fileName);
}
