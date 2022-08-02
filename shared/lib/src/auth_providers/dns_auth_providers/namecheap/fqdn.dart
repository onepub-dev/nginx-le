/* Copyright (C) S. Brett Sutton - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by Brett Sutton <bsutton@onepub.dev>, Jan 2022
 */

/// ToFqdn converts the name into a fqdn appending a trailing dot.
String toFQDN(String name) {
  final n = name.length;
  if (n == 0 || name[n - 1] == '.') {
    return name;
  }
  return '$name.';
}

/// UnFqdn converts the fqdn into a name removing the trailing dot.
String unFQDN(String name) {
  final n = name.length;
  if (n != 0 && name[n - 1] == '.') {
    return name.substring(0, n - 1);
  }
  return name;
}
