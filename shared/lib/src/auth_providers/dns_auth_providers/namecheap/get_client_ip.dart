/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

// getClientIP returns the client's public IP address.
// It uses namecheap's IP discovery service to perform the lookup.
import 'dart:convert';
import 'dart:io';

String getIPURL = 'https://dynamicdns.park-your-domain.com/getip';

Future<String?> getClientIP({bool debug = false}) async {
  final request =
      // ignore: discarded_futures
      await HttpClient().getUrl(Uri.parse(getIPURL));

  // ignore: discarded_futures
  final response = await request.close();

  String? clientIP;

  // defer
  for (final content
      in await response.transform(const Utf8Decoder()).toList()) {
    clientIP = content;
  }

  if (debug) {
    print('Client IP: $clientIP');
  }
  return clientIP;
}
