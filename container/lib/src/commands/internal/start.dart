import 'package:dshell/dshell.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../internal_run_config.dart';

void start() {
  print('Container starting');

  var debug = env('DEBUG') == 'true';
  Settings().setVerbose(enabled: debug);

  var hostname = env('HOSTNAME');
  var domain = env('DOMAIN');
  var tld = env('TLD');
  var emailaddress = env('EMAIL_ADDRESS');
  var mode = env('MODE');

  ArgumentError.checkNotNull(hostname, 'hostname');
  ArgumentError.checkNotNull(domain, 'domain');
  ArgumentError.checkNotNull(tld, 'tld');
  ArgumentError.checkNotNull(tld, 'mode');
  ArgumentError.checkNotNull(tld, 'emailaddress');

  InternalRunConfig(
          hostname: hostname,
          domain: domain,
          tld: tld,
          emailaddress: emailaddress,
          mode: mode)
      .save();

  /// Places the server into acquire mode if certificates are not valid.
  ///
  Certbot().deployCertificates(
      hostname: hostname,
      domain: domain,
      reload: false // don't try to reload nginx as it won't be running as yet.
      );

  print('Starting the certificate renewal scheduler.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(startScheduler, '');
  } finally {
    waitForEx(iso.close());
  }

  print('Starting nginx-le');

  /// run the command passed in on the command line.
  'nginx'.start();
}

/// Isolate callback must be a top level function.
void startScheduler(String arg) {
  // var config = InternalRunConfig.load();
  var renew = true;
  // if (config.mode == 'private') {
  //   /// we have nowhere to store the namecheap credentials securely so
  //   /// we can only do manual renewals.
  //   // /// we can only do a renewal if acquire has been run and we have been
  //   // /// given the namecheap credentials.
  //   // if (config.hasCredentials) {
  //   //   setEnv(NAMECHEAP_API_KEY, config.namecheap_apikey);
  //   //   setEnv(NAMECHEAP_API_USER, config.namecheap_apiuser);
  //   //   renew = true;
  //   // }
  // } else {
  //   renew = true;
  // }

  if (renew) {
    // ngix is running we now need to start the certbot renew scheduler.
    Certbot().scheduleRenews();
  }

  /// keep the isolate running forever.
  while (true) {
    sleep(10);
  }
}
