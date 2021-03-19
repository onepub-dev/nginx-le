import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

void askForLocationPath(String prompt) {
  var hostIncludePath = askForHostPath(
      title: 'Location of nginx include files',
      prompt: prompt,
      defaultPath: ConfigYaml().hostIncludePath);

  ConfigYaml().hostIncludePath = hostIncludePath;
}

String askForHostPath({String? title, String? prompt, String? defaultPath}) {
  var valid = false;
  String hostPath;
  do {
    if (title != null) print('${green(title)}');
    hostPath =
        ask('$prompt:', defaultValue: defaultPath, validator: Ask.required);

    if (!exists(hostPath)) {
      print(red('The path $hostPath does not exist.'));
      if (confirm('Create $hostPath?')) {
        if (isWritable(findParent(hostPath))) {
          createDir(hostPath, recursive: true);
        } else {
          'mkdir -p $hostPath'.start(privileged: true);
        }
        valid = true;
      }
    } else {
      valid = true;
    }

    valid = true;
  } while (!valid);

  return hostPath;
}

void createPath(String path) {
  if (!exists(path)) {
    if (isWritable(findParent(path))) {
      createDir(path, recursive: true);
    } else {
      'mkdir -p $path'.start(privileged: true);
    }
  }
}

/// climb the tree until we find a parent directory that exists.
/// If path exists we will return it.
String findParent(String path) {
  var current = path;
  while (!exists(current)) {
    current = dirname(current);
  }
  return current;
}
