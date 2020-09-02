import 'package:dcli/dcli.dart';
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

  var wildcard = Environment().wildcard;
  Settings().verbose('DOMAIN_WILDCARD=$wildcard');

  var emailaddress = Environment().emailaddress;
  Settings().verbose('EMAIL_ADDRESS=$emailaddress');
  var mode = Environment().mode;
  Settings().verbose('MODE=$mode');

  var staging = Environment().staging;
  Settings().verbose('STAGING=$staging');

  var autoAcquire = Environment().autoAcquire;
  Settings().verbose('AUTO_ACQUIRE=$autoAcquire');

  var certbotAuthProvider = Environment().certbotAuthProvider;
  Settings().verbose('CERTBOT_AUTH_PROVIDER=$certbotAuthProvider');

  /// Places the server into acquire mode if certificates are not valid.
  ///
  Certbot().deployCertificates(
      hostname: hostname,
      domain: domain,
      reload: false, // don't try to reload nginx as it won't be running as yet.
      wildcard: wildcard,
      autoAcquireMode: autoAcquire);

  startRenewalThread(debug: true);

  if (autoAcquire) {
    var certificates = Certificate.load();

    /// expired certs are handled by the renew scheduler
    if (certificates.isEmpty) {
      startAcquireThread(debug: true);
    } else {
      var certificate = certificates[0];

      /// If the certificate type has changed then we must acquire a new one.
      /// If we have more then one certificate then somethings wrong so start again by revoke all of them.
      if (certificates.length > 1 ||
          staging != certificate.staging ||
          '$hostname.$domain' != certificate.fqdn ||
          wildcard != certificate.wildcard) {
        Certbot.revokeAll();
        startAcquireThread(debug: true);
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
void startRenewalThread({bool debug = false}) {
  print('Starting the certificate renewal scheduler.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(startScheduler, debug ? 'debug' : 'nodebug');
  } finally {
    waitForEx(iso.close());
  }
}

/// Isolate callback must be a top level function.
void startScheduler(String debug) {
  if (debug == 'debug') {
    Settings().setVerbose(enabled: true);
  }
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

void startAcquireThread({bool debug = false}) {
  print('Starting the certificate acquire thread.');

  var iso = waitForEx<IsolateRunner>(IsolateRunner.spawn());

  try {
    iso.run(acquireThread, debug ? 'debug' : 'nodebug');
  } finally {
    waitForEx(iso.close());
  }
}

void acquireThread(String debug) {
  if (debug == 'debug') {
    Settings().setVerbose(enabled: true);
  }
  try {
    var authProvider = AuthProviders().getByName(Environment().certbotAuthProvider);
    authProvider.acquire();

    Certbot().deployCertificates(
        hostname: Environment().hostname,
        domain: Environment().domain,
        reload: true, // don't try to reload nginx as it won't be running as yet.
        wildcard: Environment().wildcard,
        autoAcquireMode: Environment().autoAcquire);
  } on CertbotException catch (e, st) {
    printerr(e.message);
    printerr('Cerbot Error details begin: ${'*' * 20}');
    printerr(e.details);
    printerr('Cerbot Error details end: ${'*' * 20}');
    printerr(st.toString());
    Email.sendError(subject: e.message, body: '${e.details}\n ${st.toString()}');
  } catch (e, st) {
    /// we don't rethrow as we don't want to shutdown the scheduler.
    /// as this may be a temporary error.
    printerr(e.toString());
    printerr(st.toString());

    Email.sendError(subject: e.toString(), body: st.toString());
  }
}
