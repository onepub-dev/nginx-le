import 'package:dcli/dcli.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../util/ask_fqdn_validator.dart';
import '../util/ask_location_path.dart';
import 'content_provider.dart';

class GenericProxy extends ContentProvider {
  @override
  void promptForSettings() {
    final config = ConfigYaml();
    String? fqdn;
    print('');
    print(green('Web Application Server details'));

    fqdn = config.settings[fqdnKey] as String?;
    fqdn ??= 'localhost';

    fqdn = ask('FQDN of web application server:',
        defaultValue: fqdn,
        validator: Ask.all([Ask.required, const AskFQDNOrLocalhost()]));

    var port = config.settings[portKey] as int?;
    port ??= 8080;

    port = int.parse(ask('TCP Port of web application server:',
        defaultValue: '$port',
        validator: Ask.all([Ask.required, Ask.integer])));

    config.settings[fqdnKey] = fqdn;
    config.settings[portKey] = port;

    askForLocationPath(
        'Host directory for generated proxy `.location` and `.upstream` files');
  }

  @override
  String get name => 'generic';

  @override
  String get summary => 'Generic HTTP appplication server.';

  String get portKey => '$name-port';

  String get fqdnKey => '$name-fqdn';

  @override
  void createLocationFile() {
    final config = ConfigYaml();
    final location = join(config.hostIncludePath!, '$name.location');
    find('*.location', workingDirectory: config.hostIncludePath!)
        .forEach(delete);

    location.write(r'''
location / {
      	#try_files $uri $uri/ =404;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://generic/;
        proxy_read_timeout 300;
}
''');
  }

  @override
  void createUpstreamFile() {
    final config = ConfigYaml();
    find('*.upstream', workingDirectory: ConfigYaml().hostIncludePath!)
        .forEach(delete);
    final location = join(config.hostIncludePath!, '$name.upstream');

    final fqdn = config.settings[fqdnKey] as String?;
    final port = config.settings[portKey] as int?;

    location.write('''
upstream generic {
    server $fqdn:$port fail_timeout=0;
}
''');
  }

  @override
  List<Volume> getVolumes() {
    final config = ConfigYaml();
    return [
      Volume(
          hostPath: config.hostIncludePath,
          containerPath: Nginx.containerIncludePath),
    ];
  }
}
