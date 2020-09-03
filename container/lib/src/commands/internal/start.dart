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

  var startPaused = Environment().startPaused;

  if (startPaused) {
    print(orange('Nginx-LE is paused. Run "nginx-le cli" to attached and explore the Nginx-LE container'));
    while (true) {
      sleep(10);
    }
  } else {
    _start();
  }
}

void _start() {
  var debug = Environment().debug;
  Settings().setVerbose(enabled: debug);

  var hostname = Environment().hostname;
  Settings().verbose('${Environment().hostnameKey}=$hostname');
  var domain = Environment().domain;
  Settings().verbose('${Environment().domainKey}=$domain');
  var tld = Environment().tld;
  Settings().verbose('${Environment().tldKey}=$tld');

  var wildcard = Environment().domainWildcard;
  Settings().verbose('${Environment().domainWildcardKey}=$wildcard');

  var emailaddress = Environment().emailaddress;
  Settings().verbose('${Environment().emailaddressKey}=$emailaddress');

  var production = Environment().production;
  Settings().verbose('${Environment().productionKey}=$production');

  var autoAcquire = Environment().autoAcquire;
  Settings().verbose('${Environment().autoAcquireKey}=$autoAcquire');

  var certbotAuthProvider = Environment().certbotAuthProvider;
  Settings().verbose('${Environment().certbotAuthProviderKey}=$certbotAuthProvider');

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
      startAcquireThread(debug: debug);
    } else {
      var certificate = certificates[0];

      /// If the certificate type has changed then we must acquire a new one.
      /// If we have more then one certificate then somethings wrong so start again by revoke all of them.
      if (certificates.length > 1 ||
          production != certificate.production ||
          '$hostname.$domain' != certificate.fqdn ||
          wildcard != certificate.wildcard) {
        Certbot.revokeAll();
        startAcquireThread(debug: debug);
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
        wildcard: Environment().domainWildcard,
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
