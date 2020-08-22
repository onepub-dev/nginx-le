// A challenge represents all the data needed to specify a dns-01 challenge to lets-encrypt.

import 'package:dshell/dshell.dart';
import 'package:meta/meta.dart';
import 'package:nginx_le_shared/src/certbot/certbot.dart';

import 'dns_record.dart';
import 'get_hosts.dart';
import 'get_url.dart';
import 'set_hosts.dart';

class Challenge {
  String apiKey;
  String apiUsername;
  String username;

  static const CHALLENGE_HOST_NAME = '_acme-challenge';

  // newChallenge builds a challenge record from a fqdn name and a challenge authentication key.
  Challenge.simple(
      {@required this.apiKey,
      @required this.apiUsername,
      @required this.username});

// Present installs a TXT record for the DNS challenge.
  bool present(
      {@required String hostname,
      @required String domain,
      @required String tld,
      @required String certbotAuthKey,
      int retries = 20}) {
    var records =
        _getHosts(domain: domain, tld: tld, certbotAuthKey: certbotAuthKey);

    if (records.isEmpty) {
      throw DNSProviderException(
          'No Hosts returned from NameCheap domain $hostname.$domain.');
    }

    /// certbot wont' be happy if it finds to TXT records so remove any old
    /// ones that might be hanging around.
    records = removeOldChallenge(records: records, hostname: hostname);

    if (records.length > 10) {
      throw DNSProviderException(
          'Your DNS server has more than 10 Host records. Please reduce the no. of records and try again.');
    }

    var certRecord = DNSRecord(
        name: challengeHost(hostname: hostname),
        type: 'TXT',
        address: certbotAuthKey,
        mxPref: '10',
        ttl: '${60}'); // 10 seconds because we don't want it hanging around.

    Certbot().log('creating challenge $certRecord');

    records.add(certRecord);

    setHost(
        records: records,
        apiKey: apiKey,
        apiUser: username,
        username: username,
        domain: domain,
        tld: 'org');

    return waitForRecordToBeVisible(
        certRecord: certRecord,
        hostname: hostname,
        domain: domain,
        tld: tld,
        certBotAuthKey: certbotAuthKey,
        retries: retries);
  }

  bool waitForRecordToBeVisible(
      {@required DNSRecord certRecord,
      @required String hostname,
      @required String domain,
      @required String tld,
      @required String certBotAuthKey,
      int retries}) {
    var found = false;

    // wait for upto an hour for namecheap to update the visible dns entry.
    var retryAttempts = 0;

    Certbot().log('Waiting for challenge "$certBotAuthKey" be visible');
    while (!found && retryAttempts < retries) {
      // ignore: unnecessary_cast
      var dig = 'dig +short ${challengeHost(hostname: hostname)}.${domain} TXT';
      Certbot().log('running $dig');
      var token = dig.toList(nothrow: true);

      Certbot().log('dig returned token $token');

      if (token != null && token.isNotEmpty) {
        var challenge = token[0];
        Certbot().log(
            'dig returned "$challenge" comparing $certBotAuthKey contains:  ${token.contains(certBotAuthKey)}');

        if (challenge.contains(certBotAuthKey)) {
          found = true;
          Certbot().log('DNS TXT Challenge record found!');
          break;
        } else {
          Certbot().log(
              'Stale DNS TXT acme challenge record found: $token. Ignored!');
        }
      } else {
        Certbot().log('DNS TXT acme challenge not found. Retrying.');
      }

      // forces a flush of stdout
      echo('');
      sleep(10);

      Certbot().log('Waiting for challenge Attempt: $retryAttempts');
      retryAttempts++;
    }

    return found;
  }

  // CleanUp removes a TXT record used for a previous DNS challenge.
  void cleanUp(
      {@required String hostname,
      @required String domain,
      @required String tld,
      @required String certbotAuthKey}) {
    var records =
        _getHosts(domain: domain, tld: tld, certbotAuthKey: certbotAuthKey);

    // Find the challenge TXT record and remove it if found.
    var found = false;
    var newRecords = <DNSRecord>[];
    var challengeName = challengeHost(hostname: hostname);
    Settings().verbose('Cleaning $challengeName');
    for (var h in records) {
      Settings().verbose('Found DNS: hostname=${h.name}');
      if (h.name == challengeName &&
          h.address == certbotAuthKey &&
          h.type == 'TXT') {
        found = true;
      } else {
        newRecords.add(h);
      }
    }
    if (found) {
      setHost(
          records: newRecords,
          apiKey: apiKey,
          apiUser: username,
          username: username,
          domain: domain,
          tld: 'org');
    }
  }

  List<DNSRecord> _getHosts(
      {@required String domain,
      @required String tld,
      @required String certbotAuthKey}) {
    return getHosts(
        apiKey: apiKey,
        apiUser: username,
        username: username,
        clientIP: '192.168.1.1',
        domain: domain,
        tld: 'org');
  }

  List<DNSRecord> removeOldChallenge(
      {List<DNSRecord> records, String hostname}) {
    var found = <DNSRecord>[];
    for (var h in records) {
      if (h.name == challengeHost(hostname: hostname) && h.type == 'TXT') {
        found.add(h);
      }
    }
    for (var record in found) {
      records.remove(record);
    }
    return records;
  }

  String challengeHost({String hostname}) => '$CHALLENGE_HOST_NAME.$hostname';
}
