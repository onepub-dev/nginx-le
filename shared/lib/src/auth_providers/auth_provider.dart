import 'package:nginx_le_shared/src/util/env_var.dart';

import '../../nginx_le_shared.dart';
import '../config/ConfigYaml.dart';

abstract class AuthProvider {
  String get name;

  String get summary;

  /// Provides a list of environment variables that must be passed into
  /// the docker container when it is created.
  List<EnvVar> get environment;

  void promptForSettings(ConfigYaml confi);

  /// Obtains a lets-encrypt certificate for use in a development environment where the
  /// ngix server doesn't have a public ip address.
  ///
  /// In this case we use the DNS Validation api which requires us to publish a DNS record
  /// to our DNS servers.
  ///
  /// This requires access to LastPass to obtain the DNS API keys as such this command needs to be
  /// run in an intractive terminal as you will need to login to LastPass.
  ///
  /// To avoid having to run 2fa with LastPass every time we expect that a Docker persistent volume
  /// will be mounted to /root/.lastpass.
  ///
//const tomcatPath = '$HOME/apps/tomcat vi ./apache-tomcat-9.0.16/conf/server.xml';

  /// The [hostname] and [domain] of the webserver we are obtaining certificates for.
  /// The [emailaddress] that renewal reminders will be sent to.
  /// If [mode] is public than a lets-encrypt certificate will be obtained
  ///  otherwise a staging certificate will be obtained.
  /// The default [mode] value is private.
  void acquire();

  /// overload this method if your provide needs to to have a manual auth_hook called
  void auth_hook();

  /// overload this method if your provide needs to to have a manual cleanup hook called
  void cleanup_hook();
}
