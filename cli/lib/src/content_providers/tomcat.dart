import 'package:dshell/dshell.dart';
import 'package:nginx_le/src/config/ConfigYaml.dart';
import 'package:nginx_le/src/content_providers/content_provider.dart';
import 'package:nginx_le/src/util/ask_fqdn_validator.dart';
import 'package:nginx_le/src/util/ask_location_path.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

class Tomcat extends ContentProvider {
  @override
  String get name => 'tomcat';

  @override
  String get summary => 'Tomcat web application server.';

  @override
  void promptForSettings() {
    var config = ConfigYaml();
    String fqdn;
    print('');
    print('${green('Tomcat server details')}');

    fqdn = config.settings[fqdnKey] as String;
    fqdn ??= 'localhost';

    fqdn = ask('FQDN of Tomcat server:',
        defaultValue: fqdn, validator: AskMultiValidator([Ask.required, AskFQDNOrLocalhost()]));

    var port = config.settings[portKey] as int;
    port ??= 8080;

    port = int.parse(ask('TCP Port of Tomcat server:',
        defaultValue: '$port', validator: AskMultiValidator([Ask.required, Ask.integer])));

    config.settings[fqdnKey] = fqdn;
    config.settings[portKey] = port;

    askForLocationPath('Host directory for generated tomcat `.location` and `.upstream` files');
  }

  String get portKey => '$name-port';

  String get fqdnKey => '$name-fqdn';

  @override
  void createLocationFile() {
    find('*.location', root: ConfigYaml().hostIncludePath).forEach((file) => delete(file));
    var location = join(ConfigYaml().hostIncludePath, 'tomcat.location');

    location.write(r'''location / {
      	#try_files $uri $uri/ =404;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_redirect off;
        proxy_max_temp_file_size 0;
        proxy_pass http://tomcat/;
        proxy_read_timeout 300;
}
''');
  }

  @override
  void createUpstreamFile() {
    find('*.upstream', root: ConfigYaml().hostIncludePath).forEach((file) => delete(file));
    var config = ConfigYaml();
    var location = join(ConfigYaml().hostIncludePath, 'tomcat.upstream');

    var fqdn = config.settings[fqdnKey] as String;
    var port = config.settings[portKey] as int;

    location.write('''upstream tomcat {
    server $fqdn:$port fail_timeout=0;
}
''');
  }

  @override
  List<Volume> getVolumes() {
    var config = ConfigYaml();
    return [
      Volume(hostPath: config.hostIncludePath, containerPath: Nginx.containerIncludePath),
    ];
  }
}
