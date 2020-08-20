import 'package:dshell/dshell.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../command_exeption.dart';

void acquire(List<String> args) {
  var parser = ArgParser();
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );

  var results = parser.parse(args);

  var debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  var staging = results['staging'] as bool;

  var namecheap_apikey = Environment().namecheapApiKey;
  var namecheap_apiuser = Environment().namecheapApiUser;
  var mode = Environment().mode;

  if (mode == 'private') {
    if (!(namecheap_apikey != null &&
        namecheap_apikey.isNotEmpty &&
        namecheap_apiuser != null &&
        namecheap_apiuser.isNotEmpty)) {
      throw CommandException(
          'The NameCheap arguments ${Environment.NAMECHEAP_API_KEY} and ${Environment.NAMECHEAP_API_USER} were not set');
    }

    /// these are used by the certbot auth and clenaup hooks.
    Settings().verbose('HOSTNAME:${Environment().hostname}');
    Settings().verbose('DOMAIN:${Environment().domain}');
    Settings().verbose('NAMECHEAP_API_KEY:${Environment().namecheapApiKey}');
    Settings().verbose('NAMECHEAP_API_USER:${Environment().namecheapApiUser}');
  }

  Certbot().acquire(
      hostname: Environment().hostname,
      domain: Environment().domain,
      tld: Environment().tld,
      emailaddress: Environment().emailaddress,
      mode: Environment().mode,
      staging: staging,
      debug: debug);
  Certbot().deployCertificates(
      hostname: Environment().hostname, domain: Environment().domain);
}
