/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */


import 'package:xml/xml.dart';

class DNSRecord {
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

  factory DNSRecord.fromXmlHost(XmlNode xmlHost) {
    final hostId = xmlHost.getAttribute('HostId');
    final name = xmlHost.getAttribute('Name');
    final type = xmlHost.getAttribute('Type');
    final address = xmlHost.getAttribute('Address');
    final mxPref = xmlHost.getAttribute('MXPref');
    final ttl = xmlHost.getAttribute('TTL');
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

  String? name;
  String? type;
  String? address;
  String? mxPref;
  String? ttl;
  String? hostId;
  bool isActive;
  bool isDDNSEnabled;

  @override
  String toString() =>
      'name $name, type: $type, address: $address, mxPref: $mxPref, '
      'ttl: $ttl, active: $isActive, hostId: $hostId, '
      'isDDNSEnabled: $isDDNSEnabled';
}
