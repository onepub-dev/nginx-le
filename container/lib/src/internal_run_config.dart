import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';

/// Used to store the variables that the container was started
/// with.
/// This allows subsequent commands run against the container
/// to access the startup variables.
class InternalRunConfig {
  String hostname;
  String domain;
  String tld;
  String emailaddress;
  String mode;
  bool staging;
  bool debug;

  static const savefile = '/etc/nginx-le/started-with';
  InternalRunConfig({
    @required this.hostname,
    @required this.domain,
    @required this.tld,
    @required this.emailaddress,
    @required this.mode,
    @required this.staging,
    @required this.debug,
  });

  void save() {
    savefile.write('version:1');
    savefile.append('hostname:${hostname.trim()}');
    savefile.append('domain:${domain.trim()}');
    savefile.append('tld:${tld.trim()}');
    savefile.append('emailaddress:${emailaddress.trim()}');
    savefile.append('mode:${mode.trim()}');
    savefile.append('staging:${staging}');
    savefile.append('debug:${debug}');
  }

  static InternalRunConfig load() {
    var lines = read(savefile).toList();
    var version = lines[0];
    var hostname = lines[1];
    var domain = lines[2];
    var tld = lines[3];
    var emailAddress = lines[4];
    var mode = lines[5];
    var staging = lines[6];
    var debug = lines[7];

    if (version != 'version:1') {
      throw ArgumentError.value(version, 'Invalid version');
    }

    if (!hostname.startsWith('hostname')) {
      throw ArgumentError.value(hostname, 'Expected hostname');
    }

    if (!domain.startsWith('domain')) {
      throw ArgumentError.value(domain, 'Expected domain');
    }

    if (!tld.startsWith('tld')) {
      throw ArgumentError.value(tld, 'Expected tld');
    }

    if (!emailAddress.startsWith('emailaddress')) {
      throw ArgumentError.value(emailAddress, 'Expected emailaddress');
    }

    if (!mode.startsWith('mode')) {
      throw ArgumentError.value(mode, 'Expected mode');
    }

    if (!staging.startsWith('staging')) {
      throw ArgumentError.value(mode, 'Expected staging');
    }

    if (!debug.startsWith('debug')) {
      throw ArgumentError.value(mode, 'Expected debug');
    }

    hostname = hostname.split(':')[1];
    domain = domain.split(':')[1];
    tld = tld.split(':')[1];
    emailAddress = emailAddress.split(':')[1];
    mode = mode.split(':')[1];
    staging = staging.split(':')[1];
    debug = debug.split(':')[1];

    return InternalRunConfig(
        hostname: hostname,
        domain: domain,
        tld: tld,
        emailaddress: emailAddress,
        mode: mode,
        staging: staging == 'true',
        debug: debug == 'true');
  }
}
