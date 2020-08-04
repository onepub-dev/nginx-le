import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';

abstract class Location {
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

  String get preferredHostPath => join('/', 'opt', 'nginx', 'wwwroot');

  /// The path where we store the wwwroots location config
  /// This will normally be /opt/nginx/include/wwwroot.location
  String get hostLocationConfigPath =>
      join(ConfigYaml().hostIncludePath, fileName);
}
