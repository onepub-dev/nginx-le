import 'package:dshell/dshell.dart';
import 'package:nginx_le_container/src/internal_run_config.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../command_exeption.dart';

void acquire(List<String> args) {
  var parser = ArgParser();
  parser.addOption(NAMECHEAP_API_KEY);
  parser.addOption(NAMECHEAP_API_USER);
  parser.addFlag(
    'staging',
    abbr: 's',
    negatable: false,
  );
  parser.addFlag(
    'debug',
    defaultsTo: false,
    negatable: false,
  );

  String namecheap_apikey;
  String namecheap_apiuser;

  var results = parser.parse(args);
  if (results.wasParsed(NAMECHEAP_API_KEY)) {
    namecheap_apikey = results[NAMECHEAP_API_KEY] as String;
  }

  if (results.wasParsed(NAMECHEAP_API_USER)) {
    namecheap_apiuser = results[NAMECHEAP_API_USER] as String;
  }

  var debug = results['debug'] as bool;
  Settings().setVerbose(enabled: debug);

  var staging = results['staging'] as bool;

  var config = InternalRunConfig.load();

  if (config.mode == 'private') {
    config.setcredentials(namecheap_apikey, namecheap_apiuser);

    /// TODO is this necessary?
    config.save();
    if (config.hasCredentials) {
      /// these are used by the certbot auth and clenaup hooks.
      setEnv('HOSTNAME', config.hostname);
      setEnv('DOMAIN', config.domain);
      setEnv(NAMECHEAP_API_KEY, namecheap_apikey);
      setEnv(NAMECHEAP_API_USER, namecheap_apiuser);
    } else {
      throw CommandException(
          'The NameCheap arguments $NAMECHEAP_API_KEY and $NAMECHEAP_API_USER were not set');
    }
  }

  Certbot().acquire(
      hostname: config.hostname,
      domain: config.domain,
      tld: config.tld,
      emailaddress: config.emailaddress,
      mode: config.mode,
      staging: staging,
      debug: debug);
  Certbot()
      .deployCertificates(hostname: config.hostname, domain: config.domain);
}
