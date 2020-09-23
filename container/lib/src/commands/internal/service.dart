import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:isolate/isolate.dart';
import 'package:nginx_le_shared/nginx_le_shared.dart';

import 'logrotate.dart';

/// The main service thread that runs within the docker container.
void start_service() {
  print('Nginx-LE starting Version:$packageVersion');

  /// These environment variables are set when the container is
  /// created via nginx-le config or by docker-compose.
  ///
  /// NOTE: you can NOT change these by setting an environment var before you call nginx-le start
  /// They can only be changed by re-running nginx-le config and recreating the container.
  ///
  ///

  var startPaused = Environment().startPaused;

  if (startPaused) {
    print(orange(
        'Nginx-LE is paused. Run "nginx-le cli" to attached and explore the Nginx-LE container'));
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

  dumpEnvironmentVariables();

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

  var certbotAuthProvider = Environment().authProvider;
  Settings().verbose('${Environment().authProviderKey}=$certbotAuthProvider');

  /// Places the server into acquire mode if certificates are not valid.
  ///
  Certbot().deployCertificates(
      hostname: hostname,
      domain: domain,
      reload: false, // don't try to reload nginx as it won't be running as yet.
      wildcard: wildcard,
      autoAcquireMode: autoAcquire);

  startLogRotateThread(debug: debug);

  startRenewalThread(debug: debug);

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

void dumpEnvironmentVariables() {
  printEnv(Environment().debugKey, Environment().debug.toString());
  printEnv(Environment().hostnameKey, Environment().hostname);
  printEnv(Environment().domainKey, Environment().domain);
  printEnv(Environment().tldKey, Environment().tld);
  printEnv(Environment().emailaddressKey, Environment().emailaddress);
  printEnv(Environment().productionKey, Environment().production.toString());
  printEnv(
      Environment().domainWildcardKey, Environment().domainWildcard.toString());
  printEnv(Environment().autoAcquireKey, Environment().autoAcquire.toString());
  printEnv(Environment().smtpServerKey, Environment().smtpServer);
  printEnv(
      Environment().smtpServerPortKey, Environment().smtpServerPort.toString());
  printEnv(Environment().startPausedKey, Environment().startPaused.toString());
  printEnv(Environment().authProviderKey, Environment().authProvider);

  var authProvider = AuthProviders().getByName(Environment().authProvider);
  if (authProvider == null) {
    printerr(red(
        'No Auth Provider has been set. Check ${Environment().authProviderKey} as been set'));
    exit(1);
  }
  authProvider.dumpEnvironmentVariables();

  print('Internal environment variables');
  printEnv(Environment().certbotRootPathKey, Environment().certbotRootPath);
  printEnv(Environment().logfileKey, Environment().logfile);
  printEnv(Environment().nginxCertRootPathOverwriteKey,
      Environment().nginxCertRootPathOverwrite);
}

void printEnv(String key, String value) {
  print('ENV: $key=$value');
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
  Settings().setVerbose(enabled: debug == 'debug');
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
  Settings().setVerbose(enabled: debug == 'debug');
  try {
    var authProvider = AuthProviders().getByName(Environment().authProvider);
    authProvider.acquire();

    Certbot().deployCertificates(
        hostname: Environment().hostname,
        domain: Environment().domain,
        reload:
            true, // don't try to reload nginx as it won't be running as yet.
        wildcard: Environment().domainWildcard,
        autoAcquireMode: Environment().autoAcquire);
  } on CertbotException catch (e, st) {
    printerr(e.message);
    printerr('Cerbot Error details begin: ${'*' * 20}');
    printerr(e.details);
    printerr('Cerbot Error details end: ${'*' * 20}');
    printerr(st.toString());
    Email.sendError(
        subject: e.message, body: '${e.details}\n ${st.toString()}');
  } catch (e, st) {
    /// we don't rethrow as we don't want to shutdown the scheduler.
    /// as this may be a temporary error.
    printerr(e.toString());
    printerr(st.toString());

    Email.sendError(subject: e.toString(), body: st.toString());
  }
}
