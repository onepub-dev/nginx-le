// Package namecheap implements a DNS provider for solving the DNS-01 challenge using namecheap DNS.

// Notes about namecheap's tool API:
// 1. Using the API requires registration. Once registered, use your account
//    name and API key to access the API.
// 2. There is no API to add or modify a single DNS record. Instead you must
//    read the entire list of records, make modifications, and then write the
//    entire updated list of records.  (Yuck.)
// 3. Namecheap's DNS updates can be slow to propagate. I've seen them take
//    as long as an hour.
// 4. Namecheap requires you to whitelist the IP address from which you call
//    its APIs. It also requires all API calls to include the whitelisted IP
//    address as a form or query string value. This code uses a namecheap
//    service to query the client's IP address.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'package:dshell/dshell.dart';
import 'package:pedantic/pedantic.dart';

const defaultBaseURL = 'https://api.namecheap.com/xml.response';
const sandboxBaseURL = 'https://api.sandbox.namecheap.com/xml.response';

///
/// sends a url get request and returns the resulting body.
///
String getUrl(
  String url,
) {
  // announce we are starting.
  var completer = Completer<String>();

  var client = HttpClient();
  unawaited(client.getUrl(Uri.parse(url)).then((request) {
    /// we have connected
    /// we can added headers here if we need.
    /// send the request
    return request.close();
  }).then((response) async {
    // we have a response.
    print('have response');

    print('len: ${response.contentLength}');

    var result = '';

    StreamSubscription<String> subscription;
    subscription =
        response.transform(Utf8Decoder()).transform(LineSplitter()).listen(
      (line) async {
        result += line;
      },
      onDone: () async {
        print('Completed downloading: $url');
        if (subscription != null) {
          unawaited(subscription.cancel());
        }
        completer.complete(result);
      },
      // ignore: avoid_types_on_closure_parameters
      onError: (Object e, StackTrace st) async {
        // something went wrong.

        printerr('Error downloading: $url');
        completer.completeError(e, st);
      },
      cancelOnError: true,
    );
  }));

  return waitForEx<String>(completer.future);
}

class DNSProviderException implements Exception {
  String message;
  DNSProviderException(this.message);

  @override
  String toString() => message;
}
