import 'package:dcli/dcli.dart';
import 'package:xml/xml.dart';

import 'dns_record.dart';
import 'get_url.dart';

var getHostsCommand = 'namecheap.domains.dns.getHosts';

/// [domain] - the domain e.g. noojee.com
/// [tld] - the Top Level Domain e.g. com
List<DNSRecord> getHosts(
    {required String apiUser,
    required String apiKey,
    required String username,
    required String clientIP,
    required String domain,
    required String tld}) {
  ArgumentError.checkNotNull(domain, 'domain');
  ArgumentError.checkNotNull(tld, 'tld');
  ArgumentError.checkNotNull(apiUser, 'apiUser');
  ArgumentError.checkNotNull(username, 'username');
  ArgumentError.checkNotNull(apiKey, 'apiKey');
  if (tld.startsWith('.')) {
    ArgumentError('The [tld] must not start with a dot.');
  }

  /// strip the tld as the api call only wants the domain.
  var domainPart = domain.replaceAll('.$tld', '');
  // var apiEndPoint = sandboxBaseURL;
  var apiEndPoint = defaultBaseURL;
  var url =
      '$apiEndPoint?ApiUser=$apiUser&ApiKey=$apiKey&UserName=$username&Command=$getHostsCommand&ClientIp=$clientIP&SLD=$domainPart&TLD=$tld';

  verbose(() => 'Requesting $url');
  var result = getUrl(url);
  verbose(() => 'Namecheap getHosts: $result');

  final document = XmlDocument.parse(result);

  var records = <DNSRecord>[];

  /// Check for any errors.
  var xmlErrors = document.findAllElements('Errors').first;
  var hasError = false;
  if (xmlErrors.children.isNotEmpty) {
    for (var xmlError in xmlErrors.children) {
      if (xmlError.attributes.isEmpty) continue;

      if (!hasError) {}
      var errorNo = xmlError.getAttribute('Number');
      var description = xmlError.innerText;

      throw DNSProviderException(
          'An error occured fetching the host list for $domain with tld: $tld: errorNo $errorNo - $description');
    }
  }

  /// No errors so extract the host names.
  var xmlResult = document.findAllElements('DomainDNSGetHostsResult').first;
  for (var xmlHost in xmlResult.children) {
    verbose(() => 'node: $xmlHost');
    // skip empty nodes.
    if (xmlHost.attributes.isEmpty) continue;

    if ((xmlHost as XmlElement).name.local != 'host') {
      verbose(() =>
          "Skipping Invalid NodeType: ${xmlHost.nodeType} expected a 'host' node.");
      continue;
    }
    var record = DNSRecord.fromXmlHost(xmlHost);
    verbose(() => 'Found record: $record');
    records.add(record);
  }
  return records;
}
