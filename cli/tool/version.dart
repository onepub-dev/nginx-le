import 'dart:io';

import 'package:dshell/dshell.dart';
import 'package:pub_semver/pub_semver.dart';

Version askForVersion(Version version) {
  var options = <NewVersion>[
    NewVersion('Keep the current Version'.padRight(25), version),
    NewVersion('Small Patch'.padRight(25), version.nextPatch),
    NewVersion('Non-breaking change'.padRight(25), version.nextMinor),
    NewVersion('Breaking change'.padRight(25), version.nextBreaking),
    NewVersion('Enter custom version no.'.padRight(25), null,
        getVersion: getCustomVersion),
  ];

  print('');
  print(green('What sort of changes have been made since the last release?'));
  var selected = menu(prompt: 'Select the change level:', options: options);

  print('');
  print(green('The new version is: ${selected.version}'));
  print('');
  var newVersion = confirmVersion(selected.version);
  return newVersion;
}

/// Ask the user to confirm the selected version no.
Version confirmVersion(Version version) {
  if (!confirm( 'Is this the correct version')) {
    try {
      var versionString = ask( 'Enter the new version: ');

      if (!confirm( 'Is $versionString the correct version')) {
        exit(1);
      }

      version = Version.parse(versionString);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}

class NewVersion {
  String message;
  final Version _version;
  Version Function() getVersion;

  NewVersion(this.message, this._version, {this.getVersion});

  @override
  String toString() => '$message  (${_version ?? "?"})';

  Version get version {
    if (_version == null) {
      return getVersion();
    } else {
      return _version;
    }
  }
}

/// Ask the user to type a custom version no.
Version keepVersion() {
  Version version;
  while (version == null) {
    try {
      var entered =
          ask( 'Enter the new Version No.:', validator: Ask.required);
      version = Version.parse(entered);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}

/// Ask the user to type a custom version no.
Version getCustomVersion() {
  Version version;
  while (version == null) {
    try {
      var entered =
          ask( 'Enter the new Version No.:', validator: Ask.required);
      version = Version.parse(entered);
    } on FormatException catch (e) {
      print(e);
    }
  }
  return version;
}
