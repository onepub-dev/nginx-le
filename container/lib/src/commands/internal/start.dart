import 'package:dshell/dshell.dart';
import 'package:isolate/isolate_runner.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

void start() {
  print('Nginx-LE starting Version:$packageVersion');

  /// These environment variables are set when the contianer is
  /// created via nginx-le config or by docker-compose.
  ///
  /// NOTE: you can NOT change these by setting an environment var before you call nginx-le start
  /// They can only be changed by re-running nginx-le config and recreating the container.
  ///
  var debug = Environment().debug;
  Settings().setVerbose(enabled: debug);

  var hostname = Environment().hostname;
  Settings().verbose('HOSTNAME=$hostname');
  var domain = Environment().domain;
  Settings().verbose('DOMAIN=$domain');
  var tld = Environment().tld;
  Settings().verbose('TLD=$tld');
  var emailaddress = Environment().emailaddress;
  Settings().verbose('EMAIL_ADDRESS=$emailaddress');
  var mode = Environment().mode;
  Settings().verbose('MODE=$mode');

  var staging = Environment().staging;
  Settings().verbose('STAGING=$staging');

  var autoAcquire = Environment().autoAcquire;
  Settings().verbose('AUTO_ACQUIRE=$autoAcquire');

  /// Places the server into acquire mode if certificates are not valid.
  ///
  Certbot().deployCertificates(
      hostname: hostname,
      domain: domain,
      reload: false, // don't try to reload nginx as it won't be running as yet.
      autoAcquireMode: autoAcquire);

  startRenewalThread();

  if (autoAcquire) {
    var certificates = Certificate.load();

    /// expired certs are handled by the renew scheduler
    /// If you are trying to change from a staging to a production
    /// cert then you must first revoke the staging certificate
    if (certificates.isEmpty) {
      startAcquireThread();
    } else {
      var certificate = certificates[0];

      /// not the same type of cert then acquire it.
      if (staging != certificate.staging) {
        Certbot().revoke(
            hostname: Environment().hostname,
            domain: Environment().domain,
            staging: staging);
        startAcquireThread();
      }
    }
  }

  print('Starting nginx');

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
  /// The namecheap environment vars should be inherited from the process.
  Certbot().acquire(
      hostname: Environment().hostname,
      domain: Environment().domain,
      tld: Environment().tld,
      emailaddress: Environment().emailaddress,
      mode: Environment().mode,
      staging: Environment().staging,
      debug: Environment().debug);

  Certbot().deployCertificates(
      hostname: Environment().hostname,
      domain: Environment().domain,
      reload: true // don't try to reload nginx as it won't be running as yet.
      );
}
