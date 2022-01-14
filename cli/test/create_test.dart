import 'package:dcli/dcli.dart';
import 'package:docker2/docker2.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

/// Test to create a docker container for nginx-le
void main() {
  final cmd = '''
docker create 
      --name="nginx-le" 
      --env=${Environment().hostnameKey}=www
      --env=${Environment().domainKey}=noojee.org 
      --env=${Environment().tldKey}=org
      --env=${Environment().emailaddressKey}=bsutton@noojee.com.au 
      --env=${Environment().debugKey}=false 
      --net=host --log-driver=journald -v certificates:/etc/letsencrypt 4bbc656ae28c''';

  final lines = <String>[];
  final progress = Progress(lines.add, stderr: lines.add);

  cmd.replaceAll('\n', ' ').start(nothrow: true, progress: progress);

  if (progress.exitCode != 0) {
    printerr(red('docker create failed with exitCode ${progress.exitCode}'));
    lines.forEach(print);
  } else {
    // only the first 12 characters are actually used to start/stop containers.
    final containerid = lines[0].substring(0, 12);
    if (Containers().findByContainerId(containerid) == null) {
      printerr(red('Docker failed to create the container!'));
    }
  }
}
