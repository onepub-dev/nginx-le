import 'package:dcli/dcli.dart';
import 'package:xml/xml.dart';

import '../../../../nginx_le_shared.dart';
import 'dns_record.dart';
import 'get_client_ip.dart';
import 'get_url.dart';

var setHostsCommand = 'namecheap.domains.dns.setHosts';

/// [domain] - the domain e.g. noojee.com
/// [tld] - the Top Level Domain e.g. com
void setHost(
    {required List<DNSRecord> records,
    required String? apiKey,
    required String? apiUser,
    required String? username,
    required String domain,
    required String tld}) {
  // ArgumentError.checkNotNull(fqdomainn, 'domain');
  // ArgumentError.checkNotNull(tld, 'tld');
  // ArgumentError.checkNotNull(apiUser, 'apiUser');
  // ArgumentError.checkNotNull(username, 'username');
  // ArgumentError.checkNotNull(apiKey, 'apiKey');
  if (tld.startsWith('.')) {
    ArgumentError('The [tld] must not start with a dot.');
  }

  /// strip the tld as the api call only wants the domain.
  var domainPart = domain.replaceAll('.$tld', '');
  // var apiEndPoint = sandboxBaseURL;
  var apiEndPoint = defaultBaseURL;

  var clientIP = getClientIP();
  var url =
      '$apiEndPoint?ApiUser=$apiUser&ApiKey=$apiKey&UserName=$username&Command=$setHostsCommand&ClientIp=$clientIP&SLD=$domainPart&${Environment().tldKey}=$tld';

  url += bulidRecords(records);

  Settings().verbose('Requesting $url');
  var result = getUrl(url);
  Settings().verbose('Namecheap setHosts: $result');

  final document = XmlDocument.parse(result);

  /// Check for any errors.
  var xmlErrors = document.findAllElements('Errors').first;
  if (xmlErrors.children.isNotEmpty) {
    for (var xmlError in xmlErrors.children) {
      if (xmlError.attributes.isEmpty) continue;

      var errorNo = xmlError.getAttribute('Number');
      var description = xmlError.innerText;

      throw DNSProviderException(
          'An error occured sending the host list for $domain with tld: $tld: errorNo $errorNo - $description');
    }
  }

  /// No errors so extract the host names.
  var xmlResult = document.findAllElements('DomainDNSSetHostsResult').first;
  var resultDomain = xmlResult.getAttribute('Domain');
  var success = xmlResult.getAttribute('IsSuccess') == 'true';

  if (success == false) {
    /// this should never happen as we should have been sent an error.
    throw DNSProviderException(
        'An error occured sending the host list for $domain with tld: $tld');
  }

  if (resultDomain != domain) {
    throw DNSProviderException(
        'setHost failed: the result domain $resultDomain does not match the passed domain: $domain');
  }
}

String bulidRecords(List<DNSRecord> records) {
  var url = '';

  var i = 1;
  for (var record in records) {
    url +=
        '&HostName$i=${record.name}&RecordType$i=${record.type}&Address$i=${record.address}&TTL$i=${record.ttl}';
    i++;
  }
  return url;
}
