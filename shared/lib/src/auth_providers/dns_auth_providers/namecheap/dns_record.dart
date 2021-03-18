import 'package:xml/xml.dart';

class DNSRecord {
  String? name;
  String? type;
  String? address;
  String? mxPref;
  String? ttl;
  String? hostId;
  bool isActive;
  bool isDDNSEnabled;

  DNSRecord(
      {required this.name,
      required this.type,
      required this.address,
      required this.mxPref,
      required this.ttl})
      : isActive = true,
        isDDNSEnabled = false,
        hostId = '';

  DNSRecord._internal(
      {required this.name,
      required this.type,
      required this.address,
      required this.mxPref,
      required this.ttl,
      required this.hostId,
      required this.isActive,
      required this.isDDNSEnabled});

  static DNSRecord fromXmlHost(XmlNode xmlHost) {
    var hostId = xmlHost.getAttribute('HostId');
    var name = xmlHost.getAttribute('Name');
    var type = xmlHost.getAttribute('Type');
    var address = xmlHost.getAttribute('Address');
    var mxPref = xmlHost.getAttribute('MXPref');
    var ttl = xmlHost.getAttribute('TTL');
    // ignore: unnecessary_cast
    var isActive = xmlHost.getAttribute('IsActive') as String?;
    // ignore: unnecessary_cast
    var isDDNSEnabled = xmlHost.getAttribute('IsDDNSEnabled') as String?;

    isActive ??= 'false';
    isDDNSEnabled ??= 'false';

    return DNSRecord._internal(
        hostId: hostId,
        name: name,
        type: type,
        address: address,
        mxPref: mxPref,
        ttl: ttl,
        isActive: isActive == 'true',
        isDDNSEnabled: isDDNSEnabled == 'true');
  }

  @override
  String toString() {
    return 'name $name, type: $type, address: $address, mxPref: $mxPref, ttl: $ttl, active: $isActive, hostId: $hostId, isDDNSEnabled: $isDDNSEnabled';
  }
}
