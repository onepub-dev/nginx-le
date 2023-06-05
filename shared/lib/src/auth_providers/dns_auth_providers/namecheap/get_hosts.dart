/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

import 'package:dcli/dcli.dart';
import 'package:xml/xml.dart';

import 'dns_record.dart';
import 'get_url.dart';

String getHostsCommand = 'namecheap.domains.dns.getHosts';

/// [domain] - the domain e.g. squarephone.biz
/// [tld] - the Top Level Domain e.g. com
Future<List<DNSRecord>> getHosts(
    {required String apiUser,
    required String apiKey,
    required String username,
    required String clientIP,
    required String domain,
    required String tld}) async {
  ArgumentError.checkNotNull(domain, 'domain');
  ArgumentError.checkNotNull(tld, 'tld');
  ArgumentError.checkNotNull(apiUser, 'apiUser');
  ArgumentError.checkNotNull(username, 'username');
  ArgumentError.checkNotNull(apiKey, 'apiKey');
  if (tld.startsWith('.')) {
    ArgumentError('The [tld] must not start with a dot.');
  }

  /// strip the tld as the api call only wants the domain.
  final domainPart = domain.replaceAll('.$tld', '');
  // var apiEndPoint = sandboxBaseURL;
  const apiEndPoint = defaultBaseURL;
  final url = '$apiEndPoint?ApiUser=$apiUser&ApiKey=$apiKey&'
      'UserName=$username&Command=$getHostsCommand&'
      'ClientIp=$clientIP&SLD=$domainPart&TLD=$tld';

  verbose(() => 'Requesting $url');
  final result = await getUrl(url);
  verbose(() => 'Namecheap getHosts: $result');

  final document = XmlDocument.parse(result);

  final records = <DNSRecord>[];

  /// Check for any errors.
  final xmlErrors = document.findAllElements('Errors').first;
  const hasError = false;
  if (xmlErrors.children.isNotEmpty) {
    for (final xmlError in xmlErrors.children) {
      if (xmlError.attributes.isEmpty) {
        continue;
      }

      if (!hasError) {}
      final errorNo = xmlError.getAttribute('Number');
      final description = xmlError.innerText;

      throw DNSProviderException(
          'An error occured fetching the host list for $domain with '
          'tld: $tld: errorNo $errorNo - $description');
    }
  }

  /// No errors so extract the host names.
  final xmlResult = document.findAllElements('DomainDNSGetHostsResult').first;
  for (final xmlHost in xmlResult.children) {
    verbose(() => 'node: $xmlHost');
    // skip empty nodes.
    if (xmlHost.attributes.isEmpty) {
      continue;
    }

    if ((xmlHost as XmlElement).name.local != 'host') {
      verbose(() => 'Skipping Invalid NodeType: ${xmlHost.nodeType} '
          "expected a 'host' node.");
      continue;
    }
    final record = DNSRecord.fromXmlHost(xmlHost);
    verbose(() => 'Found record: $record');
    records.add(record);
  }
  return records;
}
