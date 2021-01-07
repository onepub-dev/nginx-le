/// ToFqdn converts the name into a fqdn appending a trailing dot.
String ToFqdn(String name) {
  var n = name.length;
  if (n == 0 || name[n - 1] == '.') {
    return name;
  }
  return name + '.';
}

/// UnFqdn converts the fqdn into a name removing the trailing dot.
String UnFqdn(String name) {
  var n = name.length;
  if (n != 0 && name[n - 1] == '.') {
    return name.substring(0, n - 1);
  }
  return name;
}
