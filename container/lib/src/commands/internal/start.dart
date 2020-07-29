import 'package:dshell/dshell.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import '../../internal_run_config.dart';

void start() {
  print('Nginx-LE starting Version:$packageVersion');

  /// These environment variables are normally set when the contianer is
  /// created via nginx-le config or by docker-compose.
  var debug = env('DEBUG') == 'true';
  Settings().setVerbose(enabled: debug);

  var hostname = env('HOSTNAME');
  Settings().verbose('HOSTNAME=$hostname');
  var domain = env('DOMAIN');
  Settings().verbose('DOMAIN=$domain');
  var tld = env('TLD');
  Settings().verbose('TLD=$tld');
  var emailaddress = env('EMAIL_ADDRESS');
  Settings().verbose('EMAIL_ADDRESS=$emailaddress');
  var mode = env('MODE');
  Settings().verbose('MODE=$mode');

  var stagingString = env('STAGING');
  Settings().verbose('STAGING=$stagingString');
  stagingString ?? false;
  var staging = stagingString == 'true';

  var acquireString = env('ACQUIRE');
  Settings().verbose('ACQUIRE=$acquireString');
  acquireString ?? false;
  var acquire = acquireString == 'true';

  InternalRunConfig(
    hostname: hostname,
    domain: domain,
    tld: tld,
    emailaddress: emailaddress,
    mode: mode,
    staging: staging,
    debug: debug,
  ).save();

  /// Places the server into acquire mode if certificates are not valid.
  ///
  Certbot().deployCertificates(
      hostname: hostname,
      domain: domain,
      reload: false // don't try to reload nginx as it won't be running as yet.
      );

  startRenewalThread();

  if (acquire) {
    startAcquireThread();
  }

  print('Starting nginx-le');

  /// run the command passed in on the command line.
  'nginx'.start();
}

////////////////////////////////////////////
/// Renewal thread
////////////////////////////////////////////
void startRenewalThread() {
  print('Starting the certificate renewal scheduler.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(startScheduler, '');
  } finally {
    waitForEx(iso.close());
  }
}

/// Isolate callback must be a top level function.
void startScheduler(String _) {
  // ngix is running we now need to start the certbot renew scheduler.
  Certbot().scheduleRenews();

  /// keep the isolate running forever.
  while (true) {
    sleep(10);
  }
}

/////////////////////////////////////////////
/// Acquire thread
/////////////////////////////////////////////

void startAcquireThread() {
  print('Starting the certificate acquire thread.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(acquireThread, '');
  } finally {
    waitForEx(iso.close());
  }
}

void acquireThread(String _) {
  var config = InternalRunConfig.load();

  /// The namecheap environment vars should be inherited from the process.
  Certbot().acquire(
      hostname: config.hostname,
      domain: config.domain,
      tld: config.tld,
      emailaddress: config.emailaddress,
      mode: config.mode,
      staging: config.staging,
      debug: config.debug);

  Certbot().deployCertificates(
      hostname: config.hostname,
      domain: config.domain,
      reload: true // don't try to reload nginx as it won't be running as yet.
      );
}
