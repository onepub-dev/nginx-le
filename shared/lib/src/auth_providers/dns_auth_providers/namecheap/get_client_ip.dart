// getClientIP returns the client's public IP address.
// It uses namecheap's IP discovery service to perform the lookup.
import 'dart:convert';
import 'dart:io';

import 'package:dcli/dcli.dart';

var getIPURL = 'https://dynamicdns.park-your-domain.com/getip';

String getClientIP({bool debug = false}) {
  var request =
      waitForEx<HttpClientRequest>(HttpClient().getUrl(Uri.parse(getIPURL)));

  var response = waitForEx<HttpClientResponse>(request.close());

  String clientIP;

  // defer
  for (var content
      in waitForEx<List<String>>(response.transform(Utf8Decoder()).toList())) {
    clientIP = content;
  }

  if (debug) {
    print('Client IP: ${clientIP}');
  }
  return clientIP;
}
