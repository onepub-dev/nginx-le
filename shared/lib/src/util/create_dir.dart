import 'package:dcli/dcli.dart' as dcli;

String lcreateDir(String dir) {
  if (!dcli.exists(dir)) {
    dcli.createDir(dir, recursive: true);
  }
  return dir;
}
