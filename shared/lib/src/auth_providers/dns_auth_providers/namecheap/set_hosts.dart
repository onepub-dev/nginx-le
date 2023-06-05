/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:xml/xml.dart';

import '../../../../nginx_le_shared.dart';
import 'dns_record.dart';
import 'get_client_ip.dart';
import 'get_url.dart';

String setHostsCommand = 'namecheap.domains.dns.setHosts';

/// [domain] - the domain e.g. squarephone.ibz
/// [tld] - the Top Level Domain e.g. com
Future<void> setHost(
    {required List<DNSRecord> records,
    required String? apiKey,
    required String? apiUser,
    required String? username,
    required String domain,
    required String tld}) async {
  // ArgumentError.checkNotNull(fqdomainn, 'domain');
  // ArgumentError.checkNotNull(tld, 'tld');
  // ArgumentError.checkNotNull(apiUser, 'apiUser');
  // ArgumentError.checkNotNull(username, 'username');
  // ArgumentError.checkNotNull(apiKey, 'apiKey');
  if (tld.startsWith('.')) {
    ArgumentError('The [tld] must not start with a dot.');
  }

  /// strip the tld as the api call only wants the domain.
  final domainPart = domain.replaceAll('.$tld', '');
  // var apiEndPoint = sandboxBaseURL;
  const apiEndPoint = defaultBaseURL;

  final clientIP = await getClientIP();
  var url = '$apiEndPoint?ApiUser=$apiUser&ApiKey=$apiKey&UserName=$username'
      '&Command=$setHostsCommand&ClientIp=$clientIP&'
      'SLD=$domainPart&${Environment.tldKey}=$tld';

  url += bulidRecords(records);

  verbose(() => 'Requesting $url');
  final result = await getUrl(url);
  verbose(() => 'Namecheap setHosts: $result');

  final document = XmlDocument.parse(result);

  /// Check for any errors.
  final xmlErrors = document.findAllElements('Errors').first;
  if (xmlErrors.children.isNotEmpty) {
    for (final xmlError in xmlErrors.children) {
      if (xmlError.attributes.isEmpty) {
        continue;
      }

      final errorNo = xmlError.getAttribute('Number');
      final description = xmlError.innerText;

      throw DNSProviderException('An error occured sending the host list for '
          '$domain with tld: $tld: errorNo $errorNo - $description');
    }
  }

  /// No errors so extract the host names.
  final xmlResult = document.findAllElements('DomainDNSSetHostsResult').first;
  final resultDomain = xmlResult.getAttribute('Domain');
  final success = xmlResult.getAttribute('IsSuccess') == 'true';

  if (success == false) {
    /// this should never happen as we should have been sent an error.
    throw DNSProviderException(
        'An error occured sending the host list for $domain with tld: $tld');
  }

  if (resultDomain != domain) {
    throw DNSProviderException(
        'setHost failed: the result domain $resultDomain does '
        'not match the passed domain: $domain');
  }
}

String bulidRecords(List<DNSRecord> records) {
  final url = StringBuffer();

  var i = 1;
  for (final record in records) {
    url.write('&HostName$i=${record.name}&RecordType$i=${record.type}&'
        'Address$i=${record.address}&TTL$i=${record.ttl}');
    i++;
  }
  return url.toString();
}
